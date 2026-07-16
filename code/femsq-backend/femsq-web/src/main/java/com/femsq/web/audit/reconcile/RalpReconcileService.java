package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import com.femsq.web.audit.staging.StagingLogLevel;
import com.femsq.web.audit.stage2.RalpFkAnomalyRow;
import com.femsq.web.audit.stage2.RalpStage2Service;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=3 (Аренда земли, RALP).
 *
 * <p>Алгоритм: однократная bulk-загрузка доменных данных за год ревизии в памяти →
 * in-memory matching staging → домен → JDBC-apply (INSERT/UPDATE/DELETE).
 *
 * <p>Точно воспроизводит семантику VBA-функций {@code FindRalpRa} / {@code FindRalpRaAu}
 * из {@code Form_ra_a.cls}, устраняя per-row соединения к SQL Server.
 *
 * <p>Ключи матчинга:
 * <ul>
 *   <li>{@code ralpRa}: {@code (ralprNum, ralprDate, ralprCstAgPn, ralprOgSender)}</li>
 *   <li>{@code ralpRaAu}: {@code (ralpraRa, ralpraArrived)} — только при непустом ralprtArrived</li>
 * </ul>
 *
 * <p>Отклонение от VBA orphan-delete: при смене письма поступления в Excel старые рассмотрения того же
 * отчёта не удаляются, а закрываются синтетическим {@code returned} (см. {@link #demoteSiblingAus}).
 * Инвариант освоения: не более одного {@code sent} на {@code ralpRa}.
 */
@Service
public class RalpReconcileService extends AbstractTransactionalReconcileService {

    private static final Logger log = Logger.getLogger(RalpReconcileService.class.getName());
    private static final int TYPE_RALP = 3;

    /** Шаблон для извлечения даты в формате {@code dd.mm.yyyy} из строкового поля письма (аналог VBA {@code ParseDate}). */
    private static final Pattern DATE_PATTERN = Pattern.compile("\\b(\\d{2})\\.(\\d{2})\\.(\\d{4})\\b");

    private final RalpStage2Service ralpStage2Service;

    public RalpReconcileService(ConnectionFactory connectionFactory, RalpStage2Service ralpStage2Service) {
        super(connectionFactory);
        this.ralpStage2Service = Objects.requireNonNull(ralpStage2Service, "ralpStage2Service");
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_RALP;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection conn, ReconcileContext ctx) throws SQLException {
        long execKey = ctx.executionKey();
        boolean addRa = ctx.addRa();

        List<StgRow> staging = loadStaging(conn, execKey);
        if (staging.isEmpty()) {
            return ReconcileResult.skipped("ra_stg_ralp пустая для exec_key=" + execKey);
        }

        int year = resolveYear(staging);
        log.info("[RALP] reconcile start: exec_key=%d year=%d stagingRows=%d addRa=%b"
                .formatted(execKey, year, staging.size(), addRa));

        Map<RaKey, DomainRa> domainRa = loadDomainRa(conn, year);
        Set<Integer> domainRaKeySet = new HashSet<>();
        for (DomainRa r : domainRa.values()) {
            domainRaKeySet.add(r.key);
        }
        Map<RaAuKey, DomainRaAu> domainRaAu = loadDomainRaAu(conn, domainRaKeySet);

        log.info("[RALP] domain loaded: ralpRa=%d ralpRaAu=%d (year=%d)"
                .formatted(domainRa.size(), domainRaAu.size(), year));

        int invalid = 0;
        int emptyArrivedSkipped = 0;
        int raInserted = 0;
        int raAuInserted = 0;
        int raAuUpdated = 0;
        int unchanged = 0;
        int auDemotedSent = 0;
        int auClosedInProcess = 0;
        int auUnchangedReturned = 0;

        // Ключи, которые пережили reconcile (для определения orphan-записей под удаление)
        Set<Integer> survivingRaKeys = new HashSet<>();
        Set<Integer> survivingRaAuKeys = new HashSet<>();
        List<DemoteEvent> demoteEvents = new ArrayList<>();
        List<String> newReportLines = new ArrayList<>();
        List<String> newAuLines = new ArrayList<>();
        List<String> changedAuLines = new ArrayList<>();
        List<String> emptyArrivedLines = new ArrayList<>();
        int newReportIdx = 0;
        int newAuIdx = 0;
        int changedAuIdx = 0;

        for (StgRow row : staging) {
            if (row.cstAgPn == null || row.ogSender == null || row.date == null) {
                invalid++;
                continue;
            }

            // Нормализация номера отчёта: при представлении в филиал первый '-' → '/' (VBA-семантика)
            String normalizedNum = normalizeNum(row.num, row.presented);
            RaKey raKey = new RaKey(normalizedNum, row.date, row.cstAgPn, row.ogSender);
            DomainRa existingRa = domainRa.get(raKey);
            int raDbKey;

            if (existingRa == null) {
                // NEW: ralpRa не найден в домене
                newReportIdx++;
                newReportLines.add(Type5ReconcileTreeLineFormatter.formatRaNewLine(
                        newReportIdx,
                        row.excelRow,
                        normalizedNum,
                        row.date,
                        row.costAndVat,
                        null,
                        null,
                        null
                ));
                if (addRa) {
                    raDbKey = insertRa(conn, normalizedNum, row);
                    row.resolvedRaKey = raDbKey;
                    domainRa.put(raKey, new DomainRa(raDbKey, normalizedNum, row.date, row.cstAgPn, row.ogSender));
                    domainRaKeySet.add(raDbKey);
                    survivingRaKeys.add(raDbKey);
                    raInserted++;
                } else {
                    // dry-run: отслеживаем для счётчика, но не вставляем
                    raInserted++;
                    continue;
                }
            } else {
                raDbKey = existingRa.key;
                row.resolvedRaKey = raDbKey;
                survivingRaKeys.add(raDbKey);
                // ralpRa: VBA не обновляет поля существующих записей
            }

            // ralpRaAu обрабатывается только при непустом arrived
            String arrived = (row.arrived != null) ? row.arrived.trim() : null;
            if (arrived == null || arrived.isBlank()) {
                emptyArrivedSkipped++;
                emptyArrivedLines.add(
                        RalpReconcileAnomalyFormatter.formatEmptyArrivedHtml(row.excelRow, row.num, row.date));
                continue;
            }

            DemoteStats demoteStats = demoteSiblingAus(
                    conn, raDbKey, arrived, domainRaAu, addRa, survivingRaAuKeys, demoteEvents, row);
            auDemotedSent += demoteStats.demotedSent;
            auClosedInProcess += demoteStats.closedInProcess;
            auUnchangedReturned += demoteStats.unchangedReturned;

            RaAuKey raAuKey = new RaAuKey(raDbKey, arrived);
            DomainRaAu existingAu = domainRaAu.get(raAuKey);

            if (existingAu == null) {
                // NEW: ralpRaAu не найден
                newAuIdx++;
                newAuLines.add(formatNewAuTreeLine(newAuIdx, row, arrived));
                if (addRa) {
                    int raAuDbKey = insertRaAu(conn, raDbKey, arrived, row);
                    row.resolvedRaAuKey = raAuDbKey;
                    survivingRaAuKeys.add(raAuDbKey);
                    raAuInserted++;
                } else {
                    raAuInserted++;
                }
            } else {
                row.resolvedRaAuKey = existingAu.key;
                survivingRaAuKeys.add(existingAu.key);
                if (raAuNeedsUpdate(row, existingAu)) {
                    changedAuIdx++;
                    changedAuLines.add(formatChangedAuTreeLine(changedAuIdx, row, arrived));
                    if (addRa) {
                        updateRaAu(conn, existingAu.key, row);
                    }
                    raAuUpdated++;
                } else {
                    unchanged++;
                }
            }
        }

        // DELETE orphan ralpRaAu и ralpRa (только при addRa=true)
        int raDeleted = 0;
        int raAuDeleted = 0;
        List<String> orphanReportNums = List.of();
        if (addRa) {
            Set<Integer> orphanRaAuKeys = new HashSet<>();
            for (DomainRaAu au : domainRaAu.values()) {
                orphanRaAuKeys.add(au.key);
            }
            orphanRaAuKeys.removeAll(survivingRaAuKeys);
            if (!orphanRaAuKeys.isEmpty()) {
                raAuDeleted = deleteByKeys(conn, "DELETE FROM ags.ralpRaAu WHERE ralpraKey IN (%s)", orphanRaAuKeys);
            }

            Set<Integer> orphanRaKeys = new HashSet<>(domainRaKeySet);
            orphanRaKeys.removeAll(survivingRaKeys);
            if (!orphanRaKeys.isEmpty()) {
                orphanReportNums = loadRaNums(conn, orphanRaKeys);
                raDeleted = deleteByKeys(conn, "DELETE FROM ags.ralpRa WHERE ralprKey IN (%s)", orphanRaKeys);
            }
        } else {
            // dry-run: показать потенциальные orphan RA (если домен «лишний» относительно staging)
            Set<Integer> orphanRaKeys = new HashSet<>(domainRaKeySet);
            orphanRaKeys.removeAll(survivingRaKeys);
            if (!orphanRaKeys.isEmpty()) {
                orphanReportNums = loadRaNums(conn, orphanRaKeys);
            }
        }

        // Обновление staging-ссылок (batch)
        int stagingLinked = updateStagingRefs(conn, staging);

        appendType3ReconcileTree(
                conn,
                ctx,
                staging.size(),
                raInserted,
                raAuInserted,
                raAuUpdated,
                newReportLines,
                newAuLines,
                changedAuLines,
                emptyArrivedLines,
                orphanReportNums,
                addRa
        );
        appendReconcileAnomalyLog(ctx, demoteEvents, addRa);

        log.info(("[RALP] done: raInserted=%d raAuInserted=%d raAuUpdated=%d unchanged=%d invalid=%d"
                + " emptyArrivedSkipped=%d auDemotedSent=%d auClosedInProcess=%d auUnchangedReturned=%d"
                + " raDeleted=%d raAuDeleted=%d stagingLinked=%d")
                .formatted(raInserted, raAuInserted, raAuUpdated, unchanged, invalid, emptyArrivedSkipped,
                        auDemotedSent, auClosedInProcess, auUnchangedReturned,
                        raDeleted, raAuDeleted, stagingLinked));

        String msg = ("тип = 3 (RALP), год = %d, промежуточная таблица = %d, некорректных = %d, "
                + "без рассмотрения (пустое Поступило) = %d, "
                + "RA добавлено = %d, RA_AU добавлено = %d, RA_AU обновлено = %d, "
                + "без изменений = %d, AU понижено (отправлен) = %d, AU закрыто в процессе = %d, "
                + "AU возвращено без изменений = %d, RA удалено = %d, RA_AU удалено = %d, "
                + "обновлять БД = %s")
                .formatted(year, staging.size(), invalid, emptyArrivedSkipped,
                        raInserted, raAuInserted, raAuUpdated, unchanged,
                        auDemotedSent, auClosedInProcess, auUnchangedReturned,
                        raDeleted, raAuDeleted, addRa ? "да" : "нет");
        int affected = raInserted + raAuInserted + raAuUpdated + raDeleted + raAuDeleted;
        return addRa ? ReconcileResult.applied(affected, msg) : ReconcileResult.skipped(msg);
    }

    // -------------------------------------------------------------------------
    // Load staging
    // -------------------------------------------------------------------------

    private List<StgRow> loadStaging(Connection conn, long execKey) throws SQLException {
        String sql = """
                SELECT ralprt_key, ralprtRow, ralprtNum, ralprtDate, ralprtCstAgPn, ralprtOgSender,
                       ralprtArrived, ralprtSent, ralprtReturned, ralprtNote, ralprtStatus,
                       ralprtCostAndVat, ralprtTestStartDate, ralprtPresented
                FROM ags.ra_stg_ralp
                WHERE ralprt_exec_key = ?
                ORDER BY ralprt_key
                """;
        List<StgRow> result = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, execKey);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    StgRow row = new StgRow();
                    row.stgKey = rs.getLong("ralprt_key");
                    int excelRow = rs.getInt("ralprtRow");
                    row.excelRow = rs.wasNull() ? null : excelRow;
                    row.num = rs.getString("ralprtNum");
                    Date d = rs.getDate("ralprtDate");
                    row.date = (d != null) ? d.toLocalDate() : null;
                    int cst = rs.getInt("ralprtCstAgPn");
                    row.cstAgPn = rs.wasNull() ? null : cst;
                    int og = rs.getInt("ralprtOgSender");
                    row.ogSender = rs.wasNull() ? null : og;
                    row.arrived = rs.getString("ralprtArrived");
                    row.sent = rs.getString("ralprtSent");
                    row.returned = rs.getString("ralprtReturned");
                    row.note = rs.getString("ralprtNote");
                    row.status = rs.getInt("ralprtStatus");
                    row.costAndVat = rs.getBigDecimal("ralprtCostAndVat");
                    if (rs.wasNull()) {
                        row.costAndVat = null;
                    }
                    Date tsd = rs.getDate("ralprtTestStartDate");
                    row.testStartDate = (tsd != null) ? tsd.toLocalDate() : null;
                    int pres = rs.getInt("ralprtPresented");
                    row.presented = !rs.wasNull() && pres != 0;
                    result.add(row);
                }
            }
        }
        return result;
    }

    // -------------------------------------------------------------------------
    // Load domain data
    // -------------------------------------------------------------------------

    private Map<RaKey, DomainRa> loadDomainRa(Connection conn, int year) throws SQLException {
        String sql = """
                SELECT ralprKey, ralprNum, ralprDate, ralprCstAgPn, ralprOgSender
                FROM ags.ralpRa
                WHERE ralprY = ?
                """;
        Map<RaKey, DomainRa> map = new LinkedHashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int key = rs.getInt("ralprKey");
                    String num = rs.getString("ralprNum");
                    LocalDate date = rs.getDate("ralprDate").toLocalDate();
                    int cst = rs.getInt("ralprCstAgPn");
                    int og = rs.getInt("ralprOgSender");
                    map.put(new RaKey(num, date, cst, og), new DomainRa(key, num, date, cst, og));
                }
            }
        }
        return map;
    }

    private Map<RaAuKey, DomainRaAu> loadDomainRaAu(Connection conn, Set<Integer> raKeys) throws SQLException {
        if (raKeys.isEmpty()) {
            return new HashMap<>();
        }
        String inClause = String.join(",", Collections.nCopies(raKeys.size(), "?"));
        String sql = """
                SELECT ralpraKey, ralpraRa, ralpraArrived,
                       ralpraArrivedDate, ralpraSentDate, ralpraReturnedDate,
                       ralpraCostAndVat, ralpraSent, ralpraReturned,
                       ralpraNote, ralpraStatus, ralpraTestStartDate
                FROM ags.ralpRaAu
                WHERE ralpraRa IN (""" + inClause + ")";
        Map<RaAuKey, DomainRaAu> map = new LinkedHashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (int key : raKeys) {
                ps.setInt(idx++, key);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DomainRaAu au = new DomainRaAu();
                    au.key = rs.getInt("ralpraKey");
                    au.ralpraRa = rs.getInt("ralpraRa");
                    au.arrived = rs.getString("ralpraArrived");
                    Date arrivedD = rs.getDate("ralpraArrivedDate");
                    au.arrivedDate = (arrivedD != null) ? arrivedD.toLocalDate() : null;
                    au.costAndVat = rs.getBigDecimal("ralpraCostAndVat");
                    if (rs.wasNull()) {
                        au.costAndVat = null;
                    }
                    au.sent = rs.getString("ralpraSent");
                    Date sentD = rs.getDate("ralpraSentDate");
                    au.sentDate = (sentD != null) ? sentD.toLocalDate() : null;
                    au.returned = rs.getString("ralpraReturned");
                    Date returnedD = rs.getDate("ralpraReturnedDate");
                    au.returnedDate = (returnedD != null) ? returnedD.toLocalDate() : null;
                    au.note = rs.getString("ralpraNote");
                    au.status = rs.getInt("ralpraStatus");
                    Date tsd = rs.getDate("ralpraTestStartDate");
                    au.testStartDate = (tsd != null) ? tsd.toLocalDate() : null;
                    String arrivedKey = (au.arrived != null) ? au.arrived.trim() : "";
                    map.put(new RaAuKey(au.ralpraRa, arrivedKey), au);
                }
            }
        }
        return map;
    }

    // -------------------------------------------------------------------------
    // Demote sibling considerations (chain policy)
    // -------------------------------------------------------------------------

    /**
     * Закрывает «чужие» рассмотрения того же отчёта перед upsert текущего из Excel.
     *
     * <p>Уже закрытые возвратом ({@code returned} без {@code sent}) не изменяются. Открытые и успешные
     * ({@code sent}) переводятся в синтетический {@code returned} с очисткой {@code sent}.
     */
    private DemoteStats demoteSiblingAus(
            Connection conn,
            int raDbKey,
            String currentArrived,
            Map<RaAuKey, DomainRaAu> domainRaAu,
            boolean addRa,
            Set<Integer> survivingRaAuKeys,
            List<DemoteEvent> demoteEvents,
            StgRow stagingRow) throws SQLException {
        DemoteStats stats = new DemoteStats();
        LocalDate newArrivedDate = parseDate(currentArrived);
        List<DomainRaAu> siblings = new ArrayList<>();
        for (DomainRaAu au : domainRaAu.values()) {
            if (au.ralpraRa == raDbKey) {
                siblings.add(au);
            }
        }
        for (DomainRaAu au : siblings) {
            String auArrived = (au.arrived != null) ? au.arrived.trim() : "";
            if (auArrived.equals(currentArrived)) {
                continue;
            }
            survivingRaAuKeys.add(au.key);
            if (isReturnedOnly(au)) {
                stats.unchangedReturned++;
                continue;
            }
            LocalDate oldArrivedDate = au.arrivedDate != null ? au.arrivedDate : parseDate(au.arrived);
            LocalDate oldSentDate = au.sentDate != null ? au.sentDate : parseDate(au.sent);
            LocalDate closeDate = computeCloseDate(oldArrivedDate, oldSentDate, newArrivedDate);
            String returnedText = syntheticReturned(closeDate);
            boolean hadSent = !isBlank(au.sent);
            if (addRa) {
                demoteRaAuToReturned(conn, au.key, returnedText, closeDate);
            }
            au.sent = null;
            au.sentDate = null;
            au.returned = returnedText;
            au.returnedDate = closeDate;
            if (hadSent) {
                stats.demotedSent++;
                log.info("[RALP] demote sent→returned: ralpraKey=%d ralpraRa=%d arrived=%s closeDate=%s"
                        .formatted(au.key, raDbKey, auArrived, closeDate));
            } else {
                stats.closedInProcess++;
                log.info("[RALP] close in-process: ralpraKey=%d ralpraRa=%d arrived=%s closeDate=%s"
                        .formatted(au.key, raDbKey, auArrived, closeDate));
            }
            demoteEvents.add(new DemoteEvent(
                    stagingRow.excelRow,
                    stagingRow.num,
                    auArrived,
                    hadSent
            ));
        }
        return stats;
    }

    private void demoteRaAuToReturned(Connection conn, int raAuKey, String returnedText, LocalDate returnedDate)
            throws SQLException {
        String sql = """
                UPDATE ags.ralpRaAu SET
                    ralpraSent         = NULL,
                    ralpraSentDate     = NULL,
                    ralpraReturned     = ?,
                    ralpraReturnedDate = ?
                WHERE ralpraKey = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, returnedText);
            setDateOrNull(ps, 2, returnedDate);
            ps.setInt(3, raAuKey);
            ps.executeUpdate();
        }
    }

    private static boolean isReturnedOnly(DomainRaAu au) {
        return !isBlank(au.returned) && isBlank(au.sent);
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    /**
     * Дата синтетического возврата: день перед новым поступлением, но не раньше дат старого цикла.
     */
    static LocalDate computeCloseDate(LocalDate oldArrivedDate, LocalDate oldSentDate, LocalDate newArrivedDate) {
        LocalDate candidate = newArrivedDate != null ? newArrivedDate.minusDays(1) : LocalDate.now();
        LocalDate floor = oldArrivedDate;
        if (oldSentDate != null && (floor == null || oldSentDate.isAfter(floor))) {
            floor = oldSentDate;
        }
        if (floor == null) {
            return candidate;
        }
        return candidate.isBefore(floor) ? floor : candidate;
    }

    static String syntheticReturned(LocalDate closeDate) {
        return "автозакрытие от %02d.%02d.%04d".formatted(
                closeDate.getDayOfMonth(), closeDate.getMonthValue(), closeDate.getYear());
    }

    // -------------------------------------------------------------------------
    // INSERT / UPDATE / DELETE
    // -------------------------------------------------------------------------

    private int insertRa(Connection conn, String normalizedNum, StgRow row) throws SQLException {
        // ralprY и ralprM — вычисляемые колонки (YEAR/MONTH от ralprDate), в INSERT не указываются.
        // OUTPUT INSERTED нельзя использовать при наличии триггеров → используем RETURN_GENERATED_KEYS.
        String sqlInsert = """
                INSERT INTO ags.ralpRa (ralprNum, ralprDate, ralprCstAgPn, ralprOgSender)
                VALUES (?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, normalizedNum);
            ps.setDate(2, Date.valueOf(row.date));
            ps.setInt(3, row.cstAgPn);
            ps.setInt(4, row.ogSender);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("INSERT ralpRa: getGeneratedKeys() вернул пустой ResultSet для num=" + normalizedNum + " date=" + row.date);
    }

    private int insertRaAu(Connection conn, int raKey, String arrivedTrimmed, StgRow row) throws SQLException {
        LocalDate arrivedDate = parseDate(arrivedTrimmed);
        LocalDate sentDate = parseDate(row.sent);
        LocalDate returnedDate = parseDate(row.returned);

        // OUTPUT INSERTED нельзя использовать при наличии триггеров → RETURN_GENERATED_KEYS.
        String sqlInsert = """
                INSERT INTO ags.ralpRaAu
                    (ralpraRa, ralpraArrived, ralpraArrivedDate,
                     ralpraCostAndVat, ralpraSent, ralpraSentDate,
                     ralpraReturned, ralpraReturnedDate,
                     ralpraNote, ralpraStatus, ralpraTestStartDate)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, raKey);
            ps.setString(2, arrivedTrimmed);
            setDateOrNull(ps, 3, arrivedDate);
            setBigDecimalOrNull(ps, 4, row.costAndVat);
            setStringOrNull(ps, 5, row.sent);
            setDateOrNull(ps, 6, sentDate);
            setStringOrNull(ps, 7, row.returned);
            setDateOrNull(ps, 8, returnedDate);
            setStringOrNull(ps, 9, row.note);
            ps.setInt(10, row.status);
            setDateOrNull(ps, 11, row.testStartDate);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new SQLException("INSERT ralpRaAu: getGeneratedKeys() вернул пустой ResultSet для raKey=" + raKey + " arrived=" + arrivedTrimmed);
    }

    private void updateRaAu(Connection conn, int raAuKey, StgRow row) throws SQLException {
        LocalDate sentDate = parseDate(row.sent);
        LocalDate returnedDate = parseDate(row.returned);

        String sql = """
                UPDATE ags.ralpRaAu SET
                    ralpraCostAndVat    = ?,
                    ralpraSent          = ?,
                    ralpraSentDate      = ?,
                    ralpraReturned      = ?,
                    ralpraReturnedDate  = ?,
                    ralpraNote          = ?,
                    ralpraStatus        = ?,
                    ralpraTestStartDate = ?
                WHERE ralpraKey = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setBigDecimalOrNull(ps, 1, row.costAndVat);
            setStringOrNull(ps, 2, row.sent);
            setDateOrNull(ps, 3, sentDate);
            setStringOrNull(ps, 4, row.returned);
            setDateOrNull(ps, 5, returnedDate);
            setStringOrNull(ps, 6, row.note);
            ps.setInt(7, row.status);
            setDateOrNull(ps, 8, row.testStartDate);
            ps.setInt(9, raAuKey);
            ps.executeUpdate();
        }
    }

    private int deleteByKeys(Connection conn, String sqlTemplate, Set<Integer> keys) throws SQLException {
        if (keys.isEmpty()) {
            return 0;
        }
        String inClause = String.join(",", Collections.nCopies(keys.size(), "?"));
        String sql = sqlTemplate.formatted(inClause);
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (int k : keys) {
                ps.setInt(idx++, k);
            }
            return ps.executeUpdate();
        }
    }

    private int updateStagingRefs(Connection conn, List<StgRow> staging) throws SQLException {
        String sql = "UPDATE ags.ra_stg_ralp SET ralprtRaKey = ?, ralprtRaAuKey = ? WHERE ralprt_key = ?";
        int linked = 0;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (StgRow row : staging) {
                if (row.resolvedRaKey != null) {
                    ps.setInt(1, row.resolvedRaKey);
                    linked++;
                } else {
                    ps.setNull(1, Types.INTEGER);
                }
                if (row.resolvedRaAuKey != null) {
                    ps.setInt(2, row.resolvedRaAuKey);
                } else {
                    ps.setNull(2, Types.INTEGER);
                }
                ps.setLong(3, row.stgKey);
                ps.addBatch();
            }
            ps.executeBatch();
        }
        return linked;
    }

    // -------------------------------------------------------------------------
    // Comparison helpers
    // -------------------------------------------------------------------------

    private boolean raAuNeedsUpdate(StgRow row, DomainRaAu au) {
        return !bigDecimalEquals(row.costAndVat, au.costAndVat)
                || !strEquals(row.sent, au.sent)
                || !strEquals(row.returned, au.returned)
                || !strEquals(row.note, au.note)
                || row.status != au.status
                || !Objects.equals(row.testStartDate, au.testStartDate);
    }

    private static boolean bigDecimalEquals(BigDecimal a, BigDecimal b) {
        if (a == null && b == null) {
            return true;
        }
        if (a == null || b == null) {
            return false;
        }
        return a.compareTo(b) == 0;
    }

    private static boolean strEquals(String a, String b) {
        String na = (a == null || a.isBlank()) ? null : a.trim();
        String nb = (b == null || b.isBlank()) ? null : b.trim();
        return Objects.equals(na, nb);
    }

    // -------------------------------------------------------------------------
    // JDBC parameter helpers
    // -------------------------------------------------------------------------

    private static void setDateOrNull(PreparedStatement ps, int idx, LocalDate d) throws SQLException {
        if (d == null) {
            ps.setNull(idx, Types.DATE);
        } else {
            ps.setDate(idx, Date.valueOf(d));
        }
    }

    private static void setStringOrNull(PreparedStatement ps, int idx, String s) throws SQLException {
        if (s == null || s.isBlank()) {
            ps.setNull(idx, Types.NVARCHAR);
        } else {
            ps.setString(idx, s.trim());
        }
    }

    private static void setBigDecimalOrNull(PreparedStatement ps, int idx, BigDecimal v) throws SQLException {
        if (v == null) {
            ps.setNull(idx, Types.DECIMAL);
        } else {
            ps.setBigDecimal(idx, v);
        }
    }

    // -------------------------------------------------------------------------
    // Utility
    // -------------------------------------------------------------------------

    private static int resolveYear(List<StgRow> staging) {
        for (StgRow row : staging) {
            if (row.date != null) {
                return row.date.getYear();
            }
        }
        return LocalDate.now().getYear();
    }

    /**
     * Нормализует номер отчёта: при {@code presented=true} заменяет первое вхождение {@code '-'} на {@code '/'}
     * (VBA: {@code Replace(valueCellReNum, "-", "/", 1, 1)}).
     */
    private static String normalizeNum(String num, boolean presented) {
        if (num == null) {
            return null;
        }
        if (presented && num.contains("-")) {
            return num.replaceFirst("-", "/");
        }
        return num;
    }

    /**
     * Извлекает первую дату в формате {@code dd.mm.yyyy} из строкового поля (аналог VBA {@code ParseDate}).
     * Возвращает {@code null}, если дата не найдена или строка пуста.
     */
    static LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        Matcher m = DATE_PATTERN.matcher(s);
        if (m.find()) {
            try {
                int day = Integer.parseInt(m.group(1));
                int month = Integer.parseInt(m.group(2));
                int year = Integer.parseInt(m.group(3));
                return LocalDate.of(year, month, day);
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }

    // -------------------------------------------------------------------------
    // Inner types
    // -------------------------------------------------------------------------

    private record RaKey(String num, LocalDate date, int cstAgPn, int ogSender) {}

    private record RaAuKey(int ralpraRa, String arrived) {}

    private record DomainRa(int key, String num, LocalDate date, int cstAgPn, int ogSender) {}

    private static class DomainRaAu {
        int key;
        int ralpraRa;
        String arrived;
        LocalDate arrivedDate;
        BigDecimal costAndVat;
        String sent;
        LocalDate sentDate;
        String returned;
        LocalDate returnedDate;
        String note;
        int status;
        LocalDate testStartDate;
    }

    private static class DemoteStats {
        int demotedSent;
        int closedInProcess;
        int unchangedReturned;
    }

    private record DemoteEvent(Integer excelRow, String reportNum, String oldArrived, boolean hadSent) {
    }

    private static class StgRow {
        long stgKey;
        Integer excelRow;
        String num;
        LocalDate date;
        Integer cstAgPn;
        Integer ogSender;
        String arrived;
        String sent;
        String returned;
        String note;
        int status;
        BigDecimal costAndVat;
        LocalDate testStartDate;
        boolean presented;
        Integer resolvedRaKey;
        Integer resolvedRaAuKey;
    }

    // -------------------------------------------------------------------------
    // Audit log (0051 / §9.3.6.4 / §9.3.8.4)
    // -------------------------------------------------------------------------

    /**
     * Дерево сверки type=3 (§9.3.8.4): NEW/CHANGED / A5 / ошибки A1–A4.
     * Аномалии A1–A4 читаются на {@code conn} сверки — отдельное соединение даёт самоблокировку.
     */
    private void appendType3ReconcileTree(
            Connection conn,
            ReconcileContext ctx,
            int stagingTotal,
            int newReports,
            int newAu,
            int changedAu,
            List<String> newReportLines,
            List<String> newAuLines,
            List<String> changedAuLines,
            List<String> emptyArrivedLines,
            List<String> orphanReportNums,
            boolean addRa
    ) {
        AuditExecutionContext audit = ctx.auditExecutionContext();
        if (audit == null) {
            return;
        }
        StagingLogLevel level = resolveLogLevel(ctx);
        int detailLimit = Type5ReconcileTreeLineFormatter.detailLimit(level);

        List<String> combinedNew = new ArrayList<>(newReportLines.size() + newAuLines.size());
        combinedNew.addAll(newReportLines);
        combinedNew.addAll(newAuLines);

        List<RalpFkAnomalyRow> anomalies = ralpStage2Service.loadUnresolvedAnomalies(conn, ctx.executionKey());
        Type5ReconcileErrorGrouper.ErrorTree errors = Type5ReconcileErrorGrouper.group(
                RalpReconcileErrorMapper.toErrorHits(anomalies),
                detailLimit
        );

        RalpReconcileTreeLogger.TreeModel model = new RalpReconcileTreeLogger.TreeModel(
                stagingTotal,
                newReports,
                newAu,
                changedAu,
                Type5ReconcileTreeLineFormatter.limitLines(combinedNew, detailLimit),
                Type5ReconcileTreeLineFormatter.limitLines(changedAuLines, detailLimit),
                Type5ReconcileTreeLineFormatter.limitLines(emptyArrivedLines, detailLimit),
                errors,
                orphanReportNums == null ? List.of() : orphanReportNums,
                addRa
        );
        RalpReconcileTreeLogger.appendScaffold(audit, ctx.auditId(), ctx.executionKey(), model);
    }

    private static String formatNewAuTreeLine(int index, StgRow row, String arrived) {
        String num = row.num == null ? "—" : row.num.trim();
        String datePart = row.date == null ? "—" : row.date.format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy"));
        String rowLabel = row.excelRow == null ? "—" : String.valueOf(row.excelRow);
        return "<P>" + index + ". " + escapeHtml(rowLabel) + ". Рассмотрение к ОА № "
                + escapeHtml(num) + " от " + datePart
                + ", поступило «" + escapeHtml(arrived == null ? "—" : arrived) + "».</P>";
    }

    private static String formatChangedAuTreeLine(int index, StgRow row, String arrived) {
        String num = row.num == null ? "—" : row.num.trim();
        String rowLabel = row.excelRow == null ? "—" : String.valueOf(row.excelRow);
        return "<P>" + index + ". " + escapeHtml(rowLabel) + ". Рассмотрение ОА № "
                + escapeHtml(num) + " / поступило «" + escapeHtml(arrived == null ? "—" : arrived)
                + "»: поля направления/возврата/статуса отличаются от БД.</P>";
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private void appendReconcileAnomalyLog(
            ReconcileContext ctx,
            List<DemoteEvent> demoteEvents,
            boolean addRa
    ) {
        AuditExecutionContext audit = ctx.auditExecutionContext();
        if (audit == null) {
            return;
        }
        StagingLogLevel level = resolveLogLevel(ctx);
        if (level == StagingLogLevel.MINIMAL) {
            return;
        }

        // A5 и A1–A4 / A6 — в дереве сверки (§9.3.8.4 / A5-span), без плоских WARN.

        // A7: per-row demote only in VERBOSE (SUMMARY имеет агрегаты в details)
        if (level == StagingLogLevel.VERBOSE) {
            for (DemoteEvent event : demoteEvents) {
                Map<String, String> meta = baseMeta(ctx);
                if (event.excelRow() != null) {
                    meta.put("rowIndex", String.valueOf(event.excelRow()));
                }
                audit.append(
                        AuditLogLevel.INFO,
                        AuditLogScope.FILE,
                        "RALP_RECONCILE_AU_DEMOTE",
                        RalpReconcileAnomalyFormatter.formatDemoteHtml(
                                event.excelRow(),
                                event.reportNum(),
                                event.oldArrived(),
                                event.hadSent(),
                                addRa
                        ),
                        meta
                );
            }
        }
    }

    private List<String> loadRaNums(Connection conn, Set<Integer> raKeys) throws SQLException {
        if (raKeys.isEmpty()) {
            return List.of();
        }
        String inClause = String.join(",", Collections.nCopies(raKeys.size(), "?"));
        String sql = "SELECT ralprNum FROM ags.ralpRa WHERE ralprKey IN (" + inClause + ") ORDER BY ralprNum";
        List<String> nums = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (int key : raKeys) {
                ps.setInt(idx++, key);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String num = rs.getString(1);
                    nums.add(num == null ? "" : num);
                }
            }
        }
        return nums;
    }

    private static StagingLogLevel resolveLogLevel(ReconcileContext ctx) {
        StagingLogLevel level = ctx.auditExecutionContext().getStagingLogLevel();
        return level != null ? level : StagingLogLevel.SUMMARY;
    }

    private static Map<String, String> baseMeta(ReconcileContext ctx) {
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(ctx.auditId()));
        meta.put("executionKey", String.valueOf(ctx.executionKey()));
        meta.put("fileType", "3");
        return meta;
    }
}
