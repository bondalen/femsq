package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditMoneyFormat;
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
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Reconcile type=6 (AgFee2306): Акт ({@code ags.ogAgFee}) → Пункты ({@code ags.ogAgFeeP}).
 *
 * <p>Фазы C+D плана 26-0720: сначала заголовки, затем строки (порядок как в VBA Audit).
 *
 * <p>Порт VBA/T-SQL: ActAdd/ActDbOnlyDel/ActAttrTrue; ExcNoDel/ActPnAdd/ActPnNoEq;
 * итоговая сверка суммы за год (информационно).
 */
@Service
public class AgFee2306ReconcileService extends AbstractTransactionalReconcileService {

    private static final Logger log = Logger.getLogger(AgFee2306ReconcileService.class.getName());
    private static final int TYPE_AGFEE_2306 = 6;

    public AgFee2306ReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_AGFEE_2306;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection conn, ReconcileContext ctx) throws SQLException {
        long execKey = ctx.executionKey();
        boolean addRa = ctx.addRa();

        List<StgLine> lines = loadStaging(conn, execKey);
        if (lines.isEmpty()) {
            return ReconcileResult.skipped("ra_stg_agfee пустая для exec_key=" + execKey);
        }

        Map<ActKey, ActHeader> headers = buildHeaders(lines);
        int invalidLines = 0;
        for (StgLine line : lines) {
            if (line.senderKey == null || line.oafName == null || line.oafName.isBlank() || line.oafDate == null) {
                invalidLines++;
            }
        }

        int year = resolveYearAct(ctx, headers);
        if (year <= 0) {
            return ReconcileResult.skipped(
                    "type=6: не удалось определить год ревизии (@yearAct) из staging/контекста"
            );
        }

        Map<Integer, Integer> yearKeyByYyyy = loadYearKeys(conn);
        Integer yearKey = yearKeyByYyyy.get(year);
        if (yearKey == null) {
            return ReconcileResult.skipped("type=6: нет ags.yyyy.yKey для года " + year);
        }

        Map<ActKey, DomainAct> domain = loadDomainActs(conn, year);
        Map<Integer, String> agentNames = loadAgentDisplayNames(
                conn, collectSenderKeys(headers.keySet(), domain.keySet()));
        log.info(() -> "[AgFee] reconcile start: exec_key=%d year=%d stagingLines=%d headers=%d domainActs=%d addRa=%b"
                .formatted(execKey, year, lines.size(), headers.size(), domain.size(), addRa));

        // ----- Фаза C: Акты -----
        int actsNew = 0;
        int actsUpdated = 0;
        int actsUnchanged = 0;
        int actsAmbiguousAttrs = 0;
        int actsSkippedOtherYear = 0;
        List<String> ambiguousActLines = new ArrayList<>();
        List<Type6ReconcileTreeLogger.ActNode> missingActNodes = new ArrayList<>();
        Map<ActKey, Type6ReconcileTreeLogger.ActStatus> actStatusByKey = new LinkedHashMap<>();
        Map<ActKey, List<Type6ReconcileTreeLogger.PnNode>> actPointsByKey = new LinkedHashMap<>();

        Set<ActKey> stagingActKeys = new HashSet<>();
        for (Map.Entry<ActKey, ActHeader> entry : headers.entrySet()) {
            ActKey key = entry.getKey();
            ActHeader header = entry.getValue();

            if (key.oafDate().getYear() != year) {
                actsSkippedOtherYear++;
                continue;
            }
            stagingActKeys.add(key);
            actPointsByKey.computeIfAbsent(key, k -> new ArrayList<>());

            if (header.ambiguousAttrs()) {
                actsAmbiguousAttrs++;
                ambiguousActLines.add(formatActLabel(key, agentNames) + " (variants=" + header.attrVariants() + ")");
            }

            DomainAct existing = domain.get(key);
            if (existing == null) {
                actsNew++;
                actStatusByKey.put(key, header.ambiguousAttrs()
                        ? Type6ReconcileTreeLogger.ActStatus.ATTR_AMBIGUOUS
                        : Type6ReconcileTreeLogger.ActStatus.NEW);
                if (addRa) {
                    Integer actYearKey = yearKeyByYyyy.get(key.oafDate().getYear());
                    if (actYearKey == null) {
                        throw new SQLException("нет ags.yyyy.yKey для года акта " + key.oafDate().getYear());
                    }
                    int newKey = insertAct(conn, key, actYearKey);
                    domain.put(key, new DomainAct(newKey, key));
                    if (!header.ambiguousAttrs() && header.attrs() != null) {
                        updateActAttrs(conn, newKey, header.attrs(), actYearKey);
                    }
                }
                continue;
            }

            if (header.ambiguousAttrs()) {
                actsUnchanged++;
                actStatusByKey.put(key, Type6ReconcileTreeLogger.ActStatus.ATTR_AMBIGUOUS);
                continue;
            }
            if (header.attrs() == null) {
                actsUnchanged++;
                actStatusByKey.put(key, Type6ReconcileTreeLogger.ActStatus.UNCHANGED);
                continue;
            }

            AttrSnapshot desired = header.attrs();
            DomainAttrs current = loadActAttrs(conn, existing.oafKey());
            if (attrsEqual(current, desired, yearKey, key.oafDate().getMonthValue())) {
                actsUnchanged++;
                actStatusByKey.put(key, Type6ReconcileTreeLogger.ActStatus.UNCHANGED);
            } else {
                actsUpdated++;
                actStatusByKey.put(key, Type6ReconcileTreeLogger.ActStatus.ATTR_CHANGED);
                if (addRa) {
                    updateActAttrs(conn, existing.oafKey(), desired, yearKey);
                }
            }
        }

        int actsMissing = 0;
        List<Integer> missingActKeys = new ArrayList<>();
        for (Map.Entry<ActKey, DomainAct> entry : domain.entrySet()) {
            if (!stagingActKeys.contains(entry.getKey())) {
                actsMissing++;
                missingActKeys.add(entry.getValue().oafKey());
                missingActNodes.add(new Type6ReconcileTreeLogger.ActNode(
                        formatActLabel(entry.getKey(), agentNames),
                        Type6ReconcileTreeLogger.ActStatus.MISSING_IN_SOURCE,
                        List.of()));
            }
        }
        int actsDeleted = 0;
        if (addRa && !missingActKeys.isEmpty()) {
            actsDeleted = deleteActs(conn, missingActKeys);
            for (ActKey key : new ArrayList<>(domain.keySet())) {
                if (!stagingActKeys.contains(key)) {
                    domain.remove(key);
                }
            }
        }

        // ----- Фаза D: Пункты (после актов; порядок VBA: ExcNo → ActPnAdd → ActPnNoEq) -----
        Map<PnMatchKey, StgPn> stagingPns = buildStagingPns(lines, year);
        Map<DomainPnKey, DomainPn> domainPns = loadDomainPns(conn, year);

        int linesNew = 0;
        int linesUpdated = 0;
        int linesUnchanged = 0;
        int linesSkippedNoCst = 0;
        int linesSkippedNoTtl = 0;
        int linesAmbiguousTtl = 0;
        int linesPendingParent = 0;

        // D.3 ExcNo: сначала MISSING (как VBA), затем NEW/SUM
        Map<Integer, ActKey> oafToAct = new HashMap<>();
        for (DomainAct da : domain.values()) {
            oafToAct.put(da.oafKey(), da.key());
        }
        Set<PnMatchKey> stagingPnMatch = stagingPns.keySet();
        int linesMissing = 0;
        List<Integer> missingPnKeys = new ArrayList<>();
        for (DomainPn pn : new ArrayList<>(domainPns.values())) {
            ActKey parentAct = oafToAct.get(pn.oafKey());
            if (parentAct == null) {
                continue;
            }
            PnMatchKey mk = new PnMatchKey(parentAct, pn.cstAgPnKey());
            if (!stagingPnMatch.contains(mk)) {
                linesMissing++;
                missingPnKeys.add(pn.oafpKey());
                actPointsByKey.computeIfAbsent(parentAct, k -> new ArrayList<>()).add(
                        new Type6ReconcileTreeLogger.PnNode(
                                "cstap=" + pn.cstAgPnKey(),
                                Type6ReconcileTreeLogger.PnStatus.MISSING_IN_SOURCE,
                                null));
                if (addRa) {
                    domainPns.remove(new DomainPnKey(pn.oafKey(), pn.cstAgPnKey()));
                }
            }
        }
        int linesDeleted = 0;
        if (addRa && !missingPnKeys.isEmpty()) {
            linesDeleted = deletePns(conn, missingPnKeys);
        }

        for (StgPn stg : stagingPns.values()) {
            String pnLabel = stg.cstCode() != null ? stg.cstCode() : ("cstap=" + stg.cstAgPnKey());
            List<Type6ReconcileTreeLogger.PnNode> bucket =
                    actPointsByKey.computeIfAbsent(stg.actKey(), k -> new ArrayList<>());

            if (stg.ambiguousTtl()) {
                linesAmbiguousTtl++;
                bucket.add(new Type6ReconcileTreeLogger.PnNode(
                        pnLabel, Type6ReconcileTreeLogger.PnStatus.AMBIGUOUS_TTL,
                        "variants=" + stg.ttlVariants()));
            }

            DomainAct parent = domain.get(stg.actKey());
            if (parent == null) {
                linesPendingParent++;
                linesNew++;
                if (!stg.ambiguousTtl()) {
                    bucket.add(new Type6ReconcileTreeLogger.PnNode(
                            pnLabel, Type6ReconcileTreeLogger.PnStatus.PENDING_PARENT, null));
                }
                continue;
            }

            DomainPnKey dpk = new DomainPnKey(parent.oafKey(), stg.cstAgPnKey());
            DomainPn existing = domainPns.get(dpk);
            if (existing == null) {
                if (stg.ttl() == null) {
                    linesSkippedNoTtl++;
                    continue;
                }
                linesNew++;
                if (!stg.ambiguousTtl()) {
                    bucket.add(new Type6ReconcileTreeLogger.PnNode(
                            pnLabel, Type6ReconcileTreeLogger.PnStatus.NEW, null));
                }
                if (addRa) {
                    int oafpKey = insertPn(conn, parent.oafKey(), stg.cstAgPnKey(), stg.ttl());
                    domainPns.put(dpk, new DomainPn(oafpKey, parent.oafKey(), stg.cstAgPnKey(), stg.ttl()));
                }
                continue;
            }

            if (stg.ambiguousTtl() || stg.ttl() == null) {
                linesUnchanged++;
                continue;
            }

            if (totalsEqual(existing.total(), stg.ttl())) {
                linesUnchanged++;
                bucket.add(new Type6ReconcileTreeLogger.PnNode(
                        pnLabel, Type6ReconcileTreeLogger.PnStatus.UNCHANGED, null));
            } else {
                linesUpdated++;
                bucket.add(new Type6ReconcileTreeLogger.PnNode(
                        pnLabel, Type6ReconcileTreeLogger.PnStatus.SUM_CHANGED,
                        "БД=" + AuditMoneyFormat.format(existing.total())
                                + " ист=" + AuditMoneyFormat.format(stg.ttl())));
                if (addRa) {
                    updatePnTotal(conn, existing.oafpKey(), stg.ttl());
                }
            }
        }

        for (StgLine line : lines) {
            if (line.oafDate == null || line.oafDate.getYear() != year) {
                continue;
            }
            if (line.senderKey == null || line.oafName == null) {
                continue;
            }
            if (line.cstAgPnKey == null) {
                linesSkippedNoCst++;
            }
        }

        BigDecimal sourceSum = sumStagingTotals(stagingPns);
        BigDecimal dbSum = loadDomainYearSum(conn, year);
        BigDecimal sumDiff = sourceSum.subtract(dbSum);

        String msg = formatHumanMessage(
                year,
                lines.size(),
                headers.size(),
                invalidLines,
                actsSkippedOtherYear,
                actsNew,
                actsUpdated,
                actsUnchanged,
                actsAmbiguousAttrs,
                actsMissing,
                addRa ? actsDeleted : 0,
                linesNew,
                linesUpdated,
                linesUnchanged,
                linesAmbiguousTtl,
                linesMissing,
                addRa ? linesDeleted : 0,
                linesSkippedNoCst,
                linesSkippedNoTtl,
                linesPendingParent,
                sourceSum,
                dbSum,
                sumDiff,
                addRa
        );

        List<Type6ReconcileTreeLogger.ActNode> actNodes = new ArrayList<>();
        for (Map.Entry<ActKey, Type6ReconcileTreeLogger.ActStatus> e : actStatusByKey.entrySet()) {
            ActKey key = e.getKey();
            actNodes.add(new Type6ReconcileTreeLogger.ActNode(
                    formatActLabel(key, agentNames),
                    e.getValue(),
                    List.copyOf(actPointsByKey.getOrDefault(key, List.of()))));
        }
        Type6ReconcileTreeLogger.TreeModel tree = new Type6ReconcileTreeLogger.TreeModel(
                year,
                lines.size(),
                actNodes,
                missingActNodes,
                actsNew,
                actsUpdated,
                actsUnchanged,
                actsMissing,
                linesNew,
                linesUpdated,
                linesUnchanged,
                linesMissing,
                ambiguousActLines,
                sourceSum,
                dbSum,
                addRa
        );
        AuditExecutionContext auditCtx = ctx.auditExecutionContext();
        if (auditCtx != null) {
            Type6ReconcileTreeLogger.appendScaffold(auditCtx, ctx.auditId(), ctx.executionKey(), tree);
        }

        int affected;
        if (!addRa) {
            affected = 0;
        } else {
            affected = actsNew + actsUpdated + actsDeleted + (linesNew - linesPendingParent)
                    + linesUpdated + linesDeleted;
        }

        log.info(() -> "[AgFee] done: " + msg);
        return addRa ? ReconcileResult.applied(Math.max(affected, 0), msg) : ReconcileResult.skipped(msg);
    }

    /**
     * Человекочитаемое сообщение сверки (попадает в UI как «подробности»).
     */
    static String formatHumanMessage(
            int year,
            int stagingLines,
            int headers,
            int invalidLines,
            int actsOtherYear,
            int actsNew,
            int actsUpdated,
            int actsUnchanged,
            int actsAmbiguous,
            int actsMissing,
            int actsDeleted,
            int linesNew,
            int linesUpdated,
            int linesUnchanged,
            int linesAmbiguous,
            int linesMissing,
            int linesDeleted,
            int linesSkippedNoCst,
            int linesSkippedNoTtl,
            int linesPendingParent,
            BigDecimal sourceSum,
            BigDecimal dbSum,
            BigDecimal sumDiff,
            boolean addRa
    ) {
        StringBuilder sb = new StringBuilder();
        sb.append("акты агентского вознаграждения за ").append(year)
                .append(", строк файла = ").append(stagingLines)
                .append(", заголовков = ").append(headers);
        if (invalidLines > 0) {
            sb.append(", некорректных строк = ").append(invalidLines);
        }
        if (actsOtherYear > 0) {
            sb.append(", строк вне года = ").append(actsOtherYear);
        }
        sb.append("; актов: новые=").append(actsNew)
                .append(", изменены атрибуты=").append(actsUpdated)
                .append(", без изменений=").append(actsUnchanged);
        if (actsAmbiguous > 0) {
            sb.append(", разночтения=").append(actsAmbiguous);
        }
        sb.append(", нет в источнике=").append(actsMissing);
        if (actsDeleted > 0) {
            sb.append(", удалено=").append(actsDeleted);
        }
        sb.append("; пунктов: новые=").append(linesNew)
                .append(", изменена сумма=").append(linesUpdated)
                .append(", без изменений=").append(linesUnchanged);
        if (linesAmbiguous > 0) {
            sb.append(", неоднозначная сумма=").append(linesAmbiguous);
        }
        sb.append(", нет в источнике=").append(linesMissing);
        if (linesDeleted > 0) {
            sb.append(", удалено=").append(linesDeleted);
        }
        if (linesSkippedNoCst > 0) {
            sb.append("; строк без стройки в БД (не в сверке пунктов)=").append(linesSkippedNoCst);
        }
        if (linesSkippedNoTtl > 0) {
            sb.append("; строк без суммы=").append(linesSkippedNoTtl);
        }
        if (linesPendingParent > 0) {
            sb.append("; пунктов ожидают акт=").append(linesPendingParent);
        }
        sb.append("; сумма источник=")
                .append(AuditMoneyFormat.format(sourceSum))
                .append(", БД=")
                .append(AuditMoneyFormat.format(dbSum))
                .append(", разница=")
                .append(AuditMoneyFormat.format(sumDiff))
                .append("; обновление БД = ").append(addRa ? "да" : "нет");
        return sb.toString();
    }

    // -------------------------------------------------------------------------
    // Year scope (В6)
    // -------------------------------------------------------------------------

    /**
     * {@code @yearAct}: приоритет {@link AuditExecutionContext#getYear()}, иначе модальный год дат актов.
     */
    static int resolveYearAct(ReconcileContext ctx, Map<ActKey, ActHeader> headers) {
        AuditExecutionContext audit = ctx != null ? ctx.auditExecutionContext() : null;
        if (audit != null && audit.getYear() != null && audit.getYear() > 0) {
            return audit.getYear();
        }
        return resolveYear(headers);
    }

    /**
     * Год ревизии = модальный год дат актов в staging (при ничьей — больший).
     */
    static int resolveYear(Map<ActKey, ActHeader> headers) {
        Map<Integer, Integer> counts = new HashMap<>();
        for (ActKey key : headers.keySet()) {
            int y = key.oafDate().getYear();
            counts.merge(y, 1, Integer::sum);
        }
        int bestYear = 0;
        int bestCount = 0;
        for (Map.Entry<Integer, Integer> e : counts.entrySet()) {
            int y = e.getKey();
            int c = e.getValue();
            if (c > bestCount || (c == bestCount && y > bestYear)) {
                bestCount = c;
                bestYear = y;
            }
        }
        return bestYear;
    }

    // -------------------------------------------------------------------------
    // Load / group
    // -------------------------------------------------------------------------

    private List<StgLine> loadStaging(Connection conn, long execKey) throws SQLException {
        String sql = """
                SELECT oafpt_key, oafptOafName, oafptOafDate, oafptOafSenderKey,
                       oafptPnCstAgPn, oafptPnCstAgPnKey, oafptTtl,
                       oafptArrivedNum, oafptArrivedDate, oafptSendedNum, oafptSendedDate,
                       oafptReturnedNum, oafptReturnedDate, oafptReturnedReason,
                       oafptCapex, oafptUnit
                FROM ags.ra_stg_agfee
                WHERE oafpt_exec_key = ?
                ORDER BY oafpt_key
                """;
        List<StgLine> result = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, execKey);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    StgLine line = new StgLine();
                    line.stgKey = rs.getLong("oafpt_key");
                    line.oafName = trimToNull(rs.getString("oafptOafName"));
                    Date d = rs.getDate("oafptOafDate");
                    line.oafDate = d == null ? null : d.toLocalDate();
                    int sender = rs.getInt("oafptOafSenderKey");
                    line.senderKey = rs.wasNull() ? null : sender;
                    line.cstCode = trimToNull(rs.getString("oafptPnCstAgPn"));
                    int cstKey = rs.getInt("oafptPnCstAgPnKey");
                    line.cstAgPnKey = rs.wasNull() ? null : cstKey;
                    BigDecimal ttl = rs.getBigDecimal("oafptTtl");
                    line.ttl = rs.wasNull() ? null : ttl;
                    line.arrivedNum = trimToNull(rs.getString("oafptArrivedNum"));
                    Date ad = rs.getDate("oafptArrivedDate");
                    line.arrivedDate = ad == null ? null : ad.toLocalDate();
                    line.sendedNum = trimToNull(rs.getString("oafptSendedNum"));
                    Date sd = rs.getDate("oafptSendedDate");
                    line.sendedDate = sd == null ? null : sd.toLocalDate();
                    line.returnedNum = trimToNull(rs.getString("oafptReturnedNum"));
                    Date rd = rs.getDate("oafptReturnedDate");
                    line.returnedDate = rd == null ? null : rd.toLocalDate();
                    line.returnedReason = trimToNull(rs.getString("oafptReturnedReason"));
                    line.capex = trimToNull(rs.getString("oafptCapex"));
                    line.unit = trimToNull(rs.getString("oafptUnit"));
                    result.add(line);
                }
            }
        }
        return result;
    }

    /**
     * Группирует staging в заголовки актов. Разночтения атрибутов внутри ключа → ambiguous.
     */
    static Map<ActKey, ActHeader> buildHeaders(List<StgLine> lines) {
        Map<ActKey, LinkedHashSet<AttrSnapshot>> attrsByKey = new LinkedHashMap<>();
        for (StgLine line : lines) {
            if (line.senderKey == null || line.oafName == null || line.oafDate == null) {
                continue;
            }
            ActKey key = new ActKey(line.senderKey, line.oafName, line.oafDate);
            attrsByKey.computeIfAbsent(key, k -> new LinkedHashSet<>()).add(line.toAttrs());
        }
        Map<ActKey, ActHeader> headers = new LinkedHashMap<>();
        for (Map.Entry<ActKey, LinkedHashSet<AttrSnapshot>> entry : attrsByKey.entrySet()) {
            LinkedHashSet<AttrSnapshot> variants = entry.getValue();
            if (variants.size() == 1) {
                headers.put(entry.getKey(), new ActHeader(variants.iterator().next(), 1, false));
            } else {
                headers.put(entry.getKey(), new ActHeader(null, variants.size(), true));
            }
        }
        return headers;
    }

    /**
     * Группировка пунктов по (ActKey, cstAgPnKey); разночтения ttl → ambiguous.
     */
    static Map<PnMatchKey, StgPn> buildStagingPns(List<StgLine> lines, int year) {
        Map<PnMatchKey, LinkedHashSet<BigDecimal>> ttls = new LinkedHashMap<>();
        Map<PnMatchKey, StgLine> sample = new LinkedHashMap<>();
        for (StgLine line : lines) {
            if (line.senderKey == null || line.oafName == null || line.oafDate == null) {
                continue;
            }
            if (line.oafDate.getYear() != year || line.cstAgPnKey == null) {
                continue;
            }
            ActKey act = new ActKey(line.senderKey, line.oafName, line.oafDate);
            PnMatchKey mk = new PnMatchKey(act, line.cstAgPnKey);
            sample.putIfAbsent(mk, line);
            ttls.computeIfAbsent(mk, k -> new LinkedHashSet<>());
            if (line.ttl != null) {
                ttls.get(mk).add(line.ttl.stripTrailingZeros());
            } else {
                ttls.get(mk).add(null);
            }
        }
        Map<PnMatchKey, StgPn> result = new LinkedHashMap<>();
        for (Map.Entry<PnMatchKey, LinkedHashSet<BigDecimal>> e : ttls.entrySet()) {
            PnMatchKey mk = e.getKey();
            LinkedHashSet<BigDecimal> variants = e.getValue();
            StgLine s = sample.get(mk);
            boolean ambiguous = variants.size() > 1;
            BigDecimal ttl = (!ambiguous && variants.size() == 1) ? variants.iterator().next() : null;
            result.put(mk, new StgPn(mk.actKey(), mk.cstAgPnKey(), s.cstCode, ttl, variants.size(), ambiguous));
        }
        return result;
    }

    private Map<Integer, Integer> loadYearKeys(Connection conn) throws SQLException {
        Map<Integer, Integer> map = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement("SELECT yKey, yyyy FROM ags.yyyy");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                map.put(rs.getInt("yyyy"), rs.getInt("yKey"));
            }
        }
        return map;
    }

    private Map<ActKey, DomainAct> loadDomainActs(Connection conn, int year) throws SQLException {
        String sql = """
                SELECT oafKey, oafNum, oafDate, cstaAg
                FROM ags.ogAgFee
                WHERE YEAR(oafDate) = ?
                """;
        Map<ActKey, DomainAct> map = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Date d = rs.getDate("oafDate");
                    if (d == null) {
                        continue;
                    }
                    String num = trimToNull(rs.getString("oafNum"));
                    if (num == null) {
                        continue;
                    }
                    ActKey key = new ActKey(rs.getInt("cstaAg"), num, d.toLocalDate());
                    map.put(key, new DomainAct(rs.getInt("oafKey"), key));
                }
            }
        }
        return map;
    }

    private Map<DomainPnKey, DomainPn> loadDomainPns(Connection conn, int year) throws SQLException {
        String sql = """
                SELECT p.oafpKey, p.oafpOaf, p.oafpCstAgPn, p.oafpTotal
                FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee o ON p.oafpOaf = o.oafKey
                WHERE YEAR(o.oafDate) = ?
                """;
        Map<DomainPnKey, DomainPn> map = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal ttl = rs.getBigDecimal("oafpTotal");
                    if (rs.wasNull()) {
                        ttl = null;
                    }
                    int oaf = rs.getInt("oafpOaf");
                    int cst = rs.getInt("oafpCstAgPn");
                    map.put(new DomainPnKey(oaf, cst),
                            new DomainPn(rs.getInt("oafpKey"), oaf, cst, ttl));
                }
            }
        }
        return map;
    }

    private DomainAttrs loadActAttrs(Connection conn, int oafKey) throws SQLException {
        String sql = """
                SELECT oafArrived, oafArrivedDate, oafSent, oafSentDate,
                       oafReturned, oafReturnedDate, oafReturnedReason,
                       oafCapex, oafUnit, oafY, oafM
                FROM ags.ogAgFee
                WHERE oafKey = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, oafKey);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Date ad = rs.getDate("oafArrivedDate");
                Date sd = rs.getDate("oafSentDate");
                Date rd = rs.getDate("oafReturnedDate");
                AttrSnapshot snap = new AttrSnapshot(
                        trimToNull(rs.getString("oafArrived")),
                        ad == null ? null : ad.toLocalDate(),
                        trimToNull(rs.getString("oafSent")),
                        sd == null ? null : sd.toLocalDate(),
                        trimToNull(rs.getString("oafReturned")),
                        rd == null ? null : rd.toLocalDate(),
                        trimToNull(rs.getString("oafReturnedReason")),
                        trimToNull(rs.getString("oafCapex")),
                        trimToNull(rs.getString("oafUnit"))
                );
                return new DomainAttrs(snap, rs.getInt("oafY"), rs.getInt("oafM"));
            }
        }
    }

    private BigDecimal loadDomainYearSum(Connection conn, int year) throws SQLException {
        String sql = """
                SELECT SUM(p.oafpTotal) AS smm
                FROM ags.ogAgFee a
                JOIN ags.ogAgFeeP p ON a.oafKey = p.oafpOaf
                WHERE YEAR(a.oafDate) = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, year);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    BigDecimal s = rs.getBigDecimal("smm");
                    return s == null ? BigDecimal.ZERO : s;
                }
            }
        }
        return BigDecimal.ZERO;
    }

    static BigDecimal sumStagingTotals(Map<PnMatchKey, StgPn> stagingPns) {
        BigDecimal sum = BigDecimal.ZERO;
        for (StgPn pn : stagingPns.values()) {
            if (pn.ttl() != null && !pn.ambiguousTtl()) {
                sum = sum.add(pn.ttl());
            }
        }
        return sum;
    }

    // -------------------------------------------------------------------------
    // Apply
    // -------------------------------------------------------------------------

    private int insertAct(Connection conn, ActKey key, int yearKey) throws SQLException {
        String sql = """
                INSERT INTO ags.ogAgFee (oafNum, oafDate, cstaAg, oafY, oafM)
                VALUES (?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, key.oafName());
            ps.setDate(2, Date.valueOf(key.oafDate()));
            ps.setInt(3, key.senderKey());
            ps.setInt(4, yearKey);
            ps.setInt(5, key.oafDate().getMonthValue());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("INSERT ogAgFee did not return oafKey for " + key);
    }

    private void updateActAttrs(Connection conn, int oafKey, AttrSnapshot attrs, int yearKey)
            throws SQLException {
        String sql = """
                UPDATE ags.ogAgFee
                SET oafArrived = ?, oafArrivedDate = ?,
                    oafSent = ?, oafSentDate = ?,
                    oafReturned = ?, oafReturnedDate = ?, oafReturnedReason = ?,
                    oafCapex = ?, oafUnit = ?,
                    oafY = ?, oafM = MONTH(oafDate)
                WHERE oafKey = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            setNullableString(ps, 1, attrs.arrivedNum());
            setNullableDate(ps, 2, attrs.arrivedDate());
            setNullableString(ps, 3, attrs.sendedNum());
            setNullableDate(ps, 4, attrs.sendedDate());
            setNullableString(ps, 5, attrs.returnedNum());
            setNullableDate(ps, 6, attrs.returnedDate());
            setNullableString(ps, 7, attrs.returnedReason());
            setNullableString(ps, 8, attrs.capex());
            setNullableString(ps, 9, attrs.unit());
            ps.setInt(10, yearKey);
            ps.setInt(11, oafKey);
            ps.executeUpdate();
        }
    }

    private int deleteActs(Connection conn, List<Integer> oafKeys) throws SQLException {
        return deleteByIntKeys(conn, "DELETE FROM ags.ogAgFee WHERE oafKey IN (", oafKeys);
    }

    private int insertPn(Connection conn, int oafKey, int cstAgPnKey, BigDecimal ttl) throws SQLException {
        String sql = """
                INSERT INTO ags.ogAgFeeP (oafpOaf, oafpCstAgPn, oafpTotal)
                VALUES (?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, oafKey);
            ps.setInt(2, cstAgPnKey);
            ps.setBigDecimal(3, ttl);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }
        throw new SQLException("INSERT ogAgFeeP did not return oafpKey oaf=" + oafKey + " cst=" + cstAgPnKey);
    }

    private void updatePnTotal(Connection conn, int oafpKey, BigDecimal ttl) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE ags.ogAgFeeP SET oafpTotal = ? WHERE oafpKey = ?")) {
            ps.setBigDecimal(1, ttl);
            ps.setInt(2, oafpKey);
            ps.executeUpdate();
        }
    }

    private int deletePns(Connection conn, List<Integer> oafpKeys) throws SQLException {
        return deleteByIntKeys(conn, "DELETE FROM ags.ogAgFeeP WHERE oafpKey IN (", oafpKeys);
    }

    private int deleteByIntKeys(Connection conn, String sqlPrefix, List<Integer> keys) throws SQLException {
        if (keys.isEmpty()) {
            return 0;
        }
        StringBuilder sb = new StringBuilder(sqlPrefix);
        for (int i = 0; i < keys.size(); i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append('?');
        }
        sb.append(')');
        try (PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            for (int i = 0; i < keys.size(); i++) {
                ps.setInt(i + 1, keys.get(i));
            }
            return ps.executeUpdate();
        }
    }

    // -------------------------------------------------------------------------
    // Compare / log
    // -------------------------------------------------------------------------

    static boolean attrsEqual(DomainAttrs db, AttrSnapshot excel, int expectedYearKey, int expectedMonth) {
        if (db == null && excel == null) {
            return true;
        }
        if (db == null || excel == null) {
            return false;
        }
        AttrSnapshot snap = db.snap();
        return Objects.equals(snap.arrivedNum(), excel.arrivedNum())
                && Objects.equals(snap.arrivedDate(), excel.arrivedDate())
                && Objects.equals(snap.sendedNum(), excel.sendedNum())
                && Objects.equals(snap.sendedDate(), excel.sendedDate())
                && Objects.equals(snap.returnedNum(), excel.returnedNum())
                && Objects.equals(snap.returnedDate(), excel.returnedDate())
                && Objects.equals(snap.returnedReason(), excel.returnedReason())
                && Objects.equals(snap.capex(), excel.capex())
                && Objects.equals(snap.unit(), excel.unit())
                && db.oafY() == expectedYearKey
                && db.oafM() == expectedMonth;
    }

    static boolean totalsEqual(BigDecimal a, BigDecimal b) {
        if (a == null && b == null) {
            return true;
        }
        if (a == null || b == null) {
            return false;
        }
        return a.compareTo(b) == 0;
    }

    private static String formatActLabel(ActKey key, Map<Integer, String> agentNames) {
        String agent = null;
        if (agentNames != null) {
            agent = agentNames.get(key.senderKey());
        }
        if (agent == null || agent.isBlank()) {
            agent = "агент #" + key.senderKey();
        }
        return key.oafName() + " от " + key.oafDate() + " — " + agent;
    }

    /**
     * Собирает ключи отправителей из staging- и доменных актов.
     */
    static Set<Integer> collectSenderKeys(Set<ActKey> stagingKeys, Set<ActKey> domainKeys) {
        Set<Integer> keys = new HashSet<>();
        if (stagingKeys != null) {
            for (ActKey k : stagingKeys) {
                if (k != null) {
                    keys.add(k.senderKey());
                }
            }
        }
        if (domainKeys != null) {
            for (ActKey k : domainKeys) {
                if (k != null) {
                    keys.add(k.senderKey());
                }
            }
        }
        return keys;
    }

    /**
     * Подписи агентов из {@code ags.ogAgCs} ({@code ogaNm}, напр. «051 Газпром инвест, ООО»).
     */
    private Map<Integer, String> loadAgentDisplayNames(Connection conn, Set<Integer> senderKeys)
            throws SQLException {
        Map<Integer, String> map = new HashMap<>();
        if (senderKeys == null || senderKeys.isEmpty()) {
            return map;
        }
        StringBuilder in = new StringBuilder();
        for (Integer key : senderKeys) {
            if (key == null) {
                continue;
            }
            if (!in.isEmpty()) {
                in.append(',');
            }
            in.append(key);
        }
        if (in.isEmpty()) {
            return map;
        }
        String sql = "SELECT ogaKey, ogaNm FROM ags.ogAgCs WHERE ogaKey IN (" + in + ")";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String nm = trimToNull(rs.getString("ogaNm"));
                if (nm != null) {
                    map.put(rs.getInt("ogaKey"), nm);
                }
            }
        }
        return map;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static void setNullableString(PreparedStatement ps, int index, String value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.NVARCHAR);
        } else {
            ps.setString(index, value);
        }
    }

    private static void setNullableDate(PreparedStatement ps, int index, LocalDate value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.DATE);
        } else {
            ps.setDate(index, Date.valueOf(value));
        }
    }

    // -------------------------------------------------------------------------
    // Records
    // -------------------------------------------------------------------------

    /** Ключ матчинга акта: агент + № + дата. */
    record ActKey(int senderKey, String oafName, LocalDate oafDate) {
    }

    record AttrSnapshot(
            String arrivedNum,
            LocalDate arrivedDate,
            String sendedNum,
            LocalDate sendedDate,
            String returnedNum,
            LocalDate returnedDate,
            String returnedReason,
            String capex,
            String unit
    ) {
    }

    record ActHeader(AttrSnapshot attrs, int attrVariants, boolean ambiguousAttrs) {
    }

    record DomainAct(int oafKey, ActKey key) {
    }

    record DomainAttrs(AttrSnapshot snap, int oafY, int oafM) {
    }

    /** Ключ пункта staging: акт + стройка. */
    record PnMatchKey(ActKey actKey, int cstAgPnKey) {
    }

    /** Ключ пункта домена: oafKey + cstAgPn. */
    record DomainPnKey(int oafKey, int cstAgPnKey) {
    }

    record StgPn(
            ActKey actKey,
            int cstAgPnKey,
            String cstCode,
            BigDecimal ttl,
            int ttlVariants,
            boolean ambiguousTtl
    ) {
    }

    record DomainPn(int oafpKey, int oafKey, int cstAgPnKey, BigDecimal total) {
    }

    static final class StgLine {
        long stgKey;
        String oafName;
        LocalDate oafDate;
        Integer senderKey;
        String cstCode;
        Integer cstAgPnKey;
        BigDecimal ttl;
        String arrivedNum;
        LocalDate arrivedDate;
        String sendedNum;
        LocalDate sendedDate;
        String returnedNum;
        LocalDate returnedDate;
        String returnedReason;
        String capex;
        String unit;

        AttrSnapshot toAttrs() {
            return new AttrSnapshot(
                    arrivedNum, arrivedDate,
                    sendedNum, sendedDate,
                    returnedNum, returnedDate, returnedReason,
                    capex, unit
            );
        }
    }
}
