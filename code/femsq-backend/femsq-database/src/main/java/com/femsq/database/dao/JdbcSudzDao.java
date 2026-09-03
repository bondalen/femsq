package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplDbtP1;
import com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzInvDbtDoubleAdvice;
import com.femsq.database.model.sudz.SudzInvDbtSlot;
import com.femsq.database.model.sudz.SudzInvDbtSlotTimeline;
import com.femsq.database.model.sudz.SudzInvDbtTimelinePoint;
import com.femsq.database.model.sudz.SudzInvDbtVarCandidates;
import com.femsq.database.model.sudz.SudzInvDbtVarCnNumCandidate;
import com.femsq.database.model.sudz.SudzInvDbtVarInvNumCandidate;
import com.femsq.database.model.sudz.SudzInvDbtVarSideCandidate;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFileSh;
import com.femsq.database.model.sudz.SudzDbtUplFunnelQueueClearResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDouble;
import com.femsq.database.model.sudz.SudzDbtUplLauncher;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotLoadResult;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplNotRow;
import com.femsq.database.model.sudz.SudzDbtUplAccSmplVarInvPhaseResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarAmbiguousRow;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadPhaseResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureRow;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureSnapshot;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvContract;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvItem;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvResult;
import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadInserted;
import com.femsq.database.model.sudz.SudzDbtUplOrgNotInBuirg;
import com.femsq.database.model.sudz.SudzDbtUplTblRow;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzPmLink;
import com.femsq.database.model.sudz.SudzPmUplLookup;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
import com.femsq.database.model.sudz.SudzRsltReturnRow;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate;
import com.femsq.database.model.sudz.SudzSfDoubleHintItem;
import com.femsq.database.model.sudz.SudzSfDoubleHintSection;
import com.femsq.database.model.sudz.SudzSfDoubleAdvice;
import com.femsq.database.model.sudz.SudzSfDoubleHints;
import com.femsq.database.model.sudz.SudzSfDoubleNewSumMatch;
import com.femsq.database.model.sudz.SudzSfDoubleOldSumMatch;
import com.femsq.database.model.sudz.SudzSfDoubleSumMatches;
import com.femsq.database.model.sudz.SudzSvodAccount;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzSvodTotal;
import com.femsq.database.model.sudz.SudzUplLookup;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.model.sudz.SudzYearUpl;
import com.femsq.database.model.sudz.SudzYyyyLookup;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-доступ к СУДЗ. На DEV объекты в схеме {@code sudz} (S48); на prod — {@code ags} (S48a).
 * Префикс не берётся из {@code database.properties#schema}, чтобы не смешивать с живым {@code ags}.
 */
public class JdbcSudzDao implements SudzDao {

    private static final Logger log = Logger.getLogger(JdbcSudzDao.class.getName());

    /** Тип комментария: мероприятия. */
    private static final int CNIC_TYPE_MERY = 1;
    /** Тип комментария: куратор. */
    private static final int CNIC_TYPE_CURATOR = 8;
    /** Тип привязки стройки в cnInvCmmCst. */
    private static final int CICC_TYPE_CST = 2;

    /** Максимум строк в {@code yr_Progress} (новые сверху, старые отбрасываются). */
    private static final int MAX_YEAR_PROGRESS_LINES = 100;

    private final ConnectionFactory connectionFactory;
    private final String schema;

    /**
     * @param connectionFactory фабрика подключений
     * @param schema схема СУДЗ ({@code sudz} на DEV, {@code ags} на prod)
     */
    public JdbcSudzDao(ConnectionFactory connectionFactory, String schema) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        String trimmed = Objects.requireNonNull(schema, "schema").trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("schema СУДЗ не может быть пустой");
        }
        this.schema = trimmed;
    }

    /**
     * Квалифицированное имя объекта в схеме СУДЗ.
     *
     * @param objectName имя таблицы/view/proc
     * @return {@code schema.objectName}
     */
    private String q(String objectName) {
        return schema + "." + objectName;
    }

    @Override
    public List<SudzYear> findYears() {
        String sql = yearSelectSql() + " ORDER BY y.yr_key";
        log.log(Level.FINE, "Loading {0}.yr list enriched", schema);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<SudzYear> result = new ArrayList<>();
            while (rs.next()) {
                result.add(mapYear(rs));
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить список год-вариантов СУДЗ", exception);
        }
    }

    @Override
    public Optional<SudzYear> findYear(int yrKey) {
        String sql = yearSelectSql() + " WHERE y.yr_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapYear(rs));
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить год-вариант СУДЗ yr=" + yrKey, exception);
        }
    }

    @Override
    public Optional<SudzYearDetail> findYearDetail(int yrKey) {
        log.log(Level.FINE, "Loading year detail yr={0}", yrKey);
        try (Connection connection = connectionFactory.createConnection()) {
            Optional<SudzYear> year = findYearOn(connection, yrKey);
            if (year.isEmpty()) {
                return Optional.empty();
            }
            List<SudzYearUpl> upls = loadYearUpls(connection, yrKey);
            return Optional.of(new SudzYearDetail(year.get(), upls));
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить карточку года СУДЗ yr=" + yrKey, exception);
        }
    }

    @Override
    public List<SudzUplLookup> findUplLookups() {
        String sql = "SELECT upl_key, upl_name, upl_date, uplStatusOnDate FROM " + q("cn_inv_dbt_upl")
                + " ORDER BY upl_date, upl_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<SudzUplLookup> result = new ArrayList<>();
            while (rs.next()) {
                result.add(new SudzUplLookup(
                        rs.getInt("upl_key"),
                        rs.getString("upl_name"),
                        getLocalDate(rs, "upl_date"),
                        getLocalDate(rs, "uplStatusOnDate")
                ));
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить lookup выгрузок СУДЗ", exception);
        }
    }

    @Override
    public List<SudzCmmGrLookup> findCmmGrLookups() {
        String sql = "SELECT cnicgKey, cnicgName, cnicgDate FROM " + q("cnInvCmmGr")
                + " ORDER BY cnicgDate, cnicgKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<SudzCmmGrLookup> result = new ArrayList<>();
            while (rs.next()) {
                result.add(new SudzCmmGrLookup(
                        rs.getInt("cnicgKey"),
                        rs.getString("cnicgName"),
                        getLocalDate(rs, "cnicgDate")
                ));
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить lookup cnInvCmmGr", exception);
        }
    }

    @Override
    public List<SudzYyyyLookup> findYyyyLookups() {
        String sql = "SELECT yKey, yyyy FROM ags.yyyy ORDER BY yyyy, yKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<SudzYyyyLookup> result = new ArrayList<>();
            while (rs.next()) {
                result.add(new SudzYyyyLookup(rs.getInt("yKey"), rs.getInt("yyyy")));
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить lookup ags.yyyy", exception);
        }
    }

    @Override
    public List<SudzPmUplLookup> findPmUplLookups() {
        String sql = "SELECT cn_inv_pm_key, cn_inv_pm_name, cn_inv_pm_date FROM " + q("cn_inv_pm_upl")
                + " ORDER BY cn_inv_pm_date, cn_inv_pm_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            List<SudzPmUplLookup> result = new ArrayList<>();
            while (rs.next()) {
                result.add(new SudzPmUplLookup(
                        rs.getInt("cn_inv_pm_key"),
                        rs.getString("cn_inv_pm_name"),
                        getLocalDate(rs, "cn_inv_pm_date")
                ));
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить lookup cn_inv_pm_upl", exception);
        }
    }

    @Override
    public int createYear(
            String variant,
            Integer baseUplKey,
            String inlineUplName,
            LocalDate inlineUplDate,
            LocalDate inlineUplStatusOnDate,
            int yKey,
            Integer cmmGrKey
    ) {
        log.log(Level.INFO, "Creating sudz year variant={0}, yKey={1}", new Object[]{variant, yKey});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int uplKey;
                if (baseUplKey != null) {
                    uplKey = baseUplKey;
                    ensureUplExists(connection, uplKey);
                } else {
                    uplKey = insertUpl(connection, inlineUplName, inlineUplDate, inlineUplStatusOnDate);
                }
                ensureYyyyExists(connection, yKey);
                if (cmmGrKey != null) {
                    ensureCmmGrExists(connection, cmmGrKey);
                }

                String insertYr = "INSERT INTO " + q("yr")
                        + " (yr_variant, cn_inv_dbt_upl, yyyy, yr_CmmGr) VALUES (?, ?, ?, ?)";
                int yrKey;
                try (PreparedStatement statement = connection.prepareStatement(insertYr, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setString(1, variant);
                    statement.setInt(2, uplKey);
                    statement.setInt(3, yKey);
                    if (cmmGrKey == null) {
                        statement.setNull(4, Types.INTEGER);
                    } else {
                        statement.setInt(4, cmmGrKey);
                    }
                    statement.executeUpdate();
                    yrKey = readGeneratedKey(statement, "Не удалось получить yr_key созданного года");
                }

                insertYearUplIfAbsent(connection, yrKey, uplKey);
                connection.commit();
                log.log(Level.INFO, "Created sudz year yrKey={0}, baseUpl={1}", new Object[]{yrKey, uplKey});
                return yrKey;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать год-вариант СУДЗ", exception);
        }
    }

    @Override
    public void updateYear(
            int yrKey,
            String variant,
            int baseUplKey,
            int yKey,
            Integer cmmGrKey,
            Integer cmmGrNewKey
    ) {
        log.log(Level.INFO, "Updating sudz year yr={0}", yrKey);
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                if (findYearOn(connection, yrKey).isEmpty()) {
                    throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                }
                ensureUplExists(connection, baseUplKey);
                ensureYyyyExists(connection, yKey);
                if (cmmGrKey != null) {
                    ensureCmmGrExists(connection, cmmGrKey);
                }
                if (cmmGrNewKey != null) {
                    ensureCmmGrExists(connection, cmmGrNewKey);
                }

                // yr_Progress намеренно не обновляем
                String sql = "UPDATE " + q("yr")
                        + " SET yr_variant = ?, cn_inv_dbt_upl = ?, yyyy = ?, yr_CmmGr = ?, yr_CmmGr_New = ?"
                        + " WHERE yr_key = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, variant);
                    statement.setInt(2, baseUplKey);
                    statement.setInt(3, yKey);
                    if (cmmGrKey == null) {
                        statement.setNull(4, Types.INTEGER);
                    } else {
                        statement.setInt(4, cmmGrKey);
                    }
                    if (cmmGrNewKey == null) {
                        statement.setNull(5, Types.INTEGER);
                    } else {
                        statement.setInt(5, cmmGrNewKey);
                    }
                    statement.setInt(6, yrKey);
                    int updated = statement.executeUpdate();
                    if (updated == 0) {
                        throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                    }
                }
                insertYearUplIfAbsent(connection, yrKey, baseUplKey);
                connection.commit();
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось обновить год-вариант СУДЗ yr=" + yrKey, exception);
        }
    }

    @Override
    public int createCmmGr(String name, LocalDate date) {
        log.log(Level.INFO, "Creating cnInvCmmGr name={0}", name);
        String sql = "INSERT INTO " + q("cnInvCmmGr")
                + " (cnicgNmCs, cnicgDate, cnicgName) VALUES (?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, "S58");
            statement.setDate(2, Date.valueOf(date));
            statement.setString(3, name);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не получен cnicgKey после INSERT cnInvCmmGr");
                }
                return keys.getInt(1);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать группу комментариев", exception);
        }
    }

    @Override
    public int importRsltReturn(int yrKey, List<SudzRsltReturnRow> rows) {
        log.log(Level.INFO, "Import Rslt return yr={0}, rows={1}", new Object[]{yrKey, rows.size()});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzYear year = findYearOn(connection, yrKey)
                        .orElseThrow(() -> new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey));
                Integer cmmGrNew = year.cmmGrNew();
                if (cmmGrNew == null || cmmGrNew <= 0) {
                    throw new IllegalArgumentException(
                            "У года yr=" + yrKey + " не задана yr_CmmGr_New — укажите группу новых на Progress");
                }
                int imported = 0;
                for (SudzRsltReturnRow row : rows) {
                    if (row == null || row.dbtKey() <= 0) {
                        continue;
                    }
                    boolean any = false;
                    String curator = normalizeText(row.curatorNew());
                    String mery = normalizeText(row.meryNew());
                    String cst = normalizeText(row.cstCodeNew());
                    if (curator != null) {
                        upsertComment(connection, cmmGrNew, row.dbtKey(), CNIC_TYPE_CURATOR, curator);
                        any = true;
                    }
                    if (mery != null) {
                        upsertComment(connection, cmmGrNew, row.dbtKey(), CNIC_TYPE_MERY, mery);
                        any = true;
                    }
                    if (cst != null) {
                        upsertCst(connection, cmmGrNew, row.dbtKey(), cst);
                        any = true;
                    }
                    if (any) {
                        imported++;
                    }
                }
                connection.commit();
                return imported;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось импортировать возврат Rslt yr=" + yrKey, exception);
        }
    }

    @Override
    public String appendYearProgress(int yrKey, String line) {
        log.log(Level.INFO, "Appending yr_Progress yr={0}", yrKey);
        String readSql = "SELECT yr_Progress FROM " + q("yr") + " WHERE yr_key = ?";
        String updateSql = "UPDATE " + q("yr") + " SET yr_Progress = ? WHERE yr_key = ?";
        try (Connection connection = connectionFactory.createConnection()) {
            if (findYearOn(connection, yrKey).isEmpty()) {
                throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
            }
            String current;
            try (PreparedStatement statement = connection.prepareStatement(readSql)) {
                statement.setInt(1, yrKey);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                    }
                    current = rs.getString(1);
                }
            }
            String merged = mergeYearProgress(current, line, MAX_YEAR_PROGRESS_LINES);
            try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                statement.setString(1, merged);
                statement.setInt(2, yrKey);
                statement.executeUpdate();
            }
            return merged;
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось дописать yr_Progress yr=" + yrKey, exception);
        }
    }

    /**
     * Новая строка в начало лога; не больше {@code maxLines} строк.
     *
     * @param current текущий {@code yr_Progress} (может быть {@code null})
     * @param line новая строка
     * @param maxLines лимит строк
     * @return текст для записи
     */
    static String mergeYearProgress(String current, String line, int maxLines) {
        String incoming = line == null ? "" : line.trim();
        if (incoming.isEmpty()) {
            return current == null ? "" : current;
        }
        List<String> lines = new ArrayList<>();
        lines.add(incoming);
        if (current != null && !current.isBlank()) {
            for (String existing : current.split("\\R", -1)) {
                if (existing != null && !existing.isBlank()) {
                    lines.add(existing);
                }
            }
        }
        if (lines.size() > maxLines) {
            lines.subList(maxLines, lines.size()).clear();
        }
        return String.join("\r\n", lines);
    }

    @Override
    public void deleteYear(int yrKey) {
        log.log(Level.INFO, "Deleting sudz year yr={0}", yrKey);
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                if (findYearOn(connection, yrKey).isEmpty()) {
                    throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                }
                try (PreparedStatement deleteUpls = connection.prepareStatement(
                        "DELETE FROM " + q("yr_upl_p") + " WHERE yr_upl_p_yr = ?")) {
                    deleteUpls.setInt(1, yrKey);
                    deleteUpls.executeUpdate();
                }
                try (PreparedStatement deleteYr = connection.prepareStatement(
                        "DELETE FROM " + q("yr") + " WHERE yr_key = ?")) {
                    deleteYr.setInt(1, yrKey);
                    int deleted = deleteYr.executeUpdate();
                    if (deleted == 0) {
                        throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                    }
                }
                connection.commit();
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось удалить год-вариант СУДЗ yr=" + yrKey
                    + " (возможно, блокирует FK)", exception);
        }
    }

    @Override
    public int createUpl(String name, LocalDate uplDate, LocalDate statusOnDate) {
        log.log(Level.INFO, "Creating sudz upl name={0}", name);
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int uplKey = insertUpl(connection, name, uplDate, statusOnDate);
                connection.commit();
                return uplKey;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать выгрузку СУДЗ", exception);
        }
    }

    @Override
    public SudzYearUpl addYearUpl(int yrKey, int uplKey) {
        log.log(Level.INFO, "Adding upl={0} to yr={1}", new Object[]{uplKey, yrKey});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                if (findYearOn(connection, yrKey).isEmpty()) {
                    throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                }
                ensureUplExists(connection, uplKey);
                int yrUplPKey = insertYearUplIfAbsent(connection, yrKey, uplKey);
                connection.commit();
                return loadYearUpl(connection, yrUplPKey);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось добавить выгрузку в год yr=" + yrKey, exception);
        }
    }

    @Override
    public void removeYearUpl(int yrUplPKey) {
        log.log(Level.INFO, "Removing yr_upl_p={0}", yrUplPKey);
        String sql = "DELETE FROM " + q("yr_upl_p") + " WHERE yr_upl_p_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrUplPKey);
            int deleted = statement.executeUpdate();
            if (deleted == 0) {
                throw new IllegalArgumentException("Строка yr_upl_p не найдена: key=" + yrUplPKey);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось удалить yr_upl_p=" + yrUplPKey, exception);
        }
    }

    @Override
    public int createPmUpl(String name, LocalDate date) {
        log.log(Level.INFO, "Creating sudz pm upl name={0}", name);
        String sql = "INSERT INTO " + q("cn_inv_pm_upl")
                + " (cn_inv_pm_date, cn_inv_pm_name) VALUES (?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setDate(1, Date.valueOf(date));
            statement.setString(2, name);
            statement.executeUpdate();
            return readGeneratedKey(statement, "Не удалось получить cn_inv_pm_key");
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать выгрузку платежей СУДЗ", exception);
        }
    }

    @Override
    public SudzPmLink addPmLink(int dbtUplKey, int pmKey) {
        log.log(Level.INFO, "Linking dbtUpl={0} to pm={1}", new Object[]{dbtUplKey, pmKey});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ensureUplExists(connection, dbtUplKey);
                ensurePmExists(connection, pmKey);

                Integer existing = findPmLinkKey(connection, dbtUplKey, pmKey);
                int gPKey;
                if (existing != null) {
                    gPKey = existing;
                } else {
                    String sql = "INSERT INTO " + q("cn_inv_dbt_upl_g_p")
                            + " (cn_inv_pm_upl, cn_inv_dbt_upl) VALUES (?, ?)";
                    try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                        statement.setInt(1, pmKey);
                        statement.setInt(2, dbtUplKey);
                        statement.executeUpdate();
                        gPKey = readGeneratedKey(statement, "Не удалось получить g_p [key]");
                    }
                }
                connection.commit();
                return loadPmLink(connection, gPKey);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось связать выгрузку ДЗ с платежами", exception);
        }
    }

    @Override
    public void removePmLink(int gPKey) {
        log.log(Level.INFO, "Removing pm link gPKey={0}", gPKey);
        String sql = "DELETE FROM " + q("cn_inv_dbt_upl_g_p") + " WHERE [key] = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, gPKey);
            int deleted = statement.executeUpdate();
            if (deleted == 0) {
                throw new IllegalArgumentException("Связь g_p не найдена: key=" + gPKey);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось удалить связь g_p=" + gPKey, exception);
        }
    }

    @Override
    public List<SudzRsltDebt> findYrDbtChanges(int yrKey, Integer asOfUpl) {
        String sql = ""
                + "SELECT f.dbtKey, f.upl_key, f.upl_date, f.as_of, "
                + "       f.invNumEnum, f.idNum, f.cnNumEnum, f.csoCnDate, "
                + "       f.org_id_value_l, f.ITN, f.CtptOrg, "
                + "       f.dvDateMaturity, f.dvTtl, f.dvOverd, "
                + "       f.CstAgPnCode, f.CstAgPnName, f.AgOrg, "
                + "       CAST(f.account_num AS nvarchar(32)) AS account_num, "
                + "       cm.curator, cm.mery, "
                + "       cy.cst_code, cy.cst_name, "
                + "       cmn.curator_new, cmn.mery_new, cyn.cst_code_new "
                + "FROM " + q("vw_Yr_DbtFact") + " f "
                + "LEFT JOIN ( "
                + "  SELECT cm.cnicInvAccnt AS dbtKey, "
                + "         MAX(CASE WHEN cm.cnicType = 8 THEN cm.cnicText END) AS curator, "
                + "         MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery "
                + "  FROM " + q("yr") + " y "
                + "  JOIN " + q("cnInvCmm") + " cm ON cm.cnicGroup = y.yr_CmmGr "
                + "  WHERE y.yr_key = ? "
                + "  GROUP BY cm.cnicInvAccnt "
                + ") cm ON cm.dbtKey = f.dbtKey "
                + "LEFT JOIN ( "
                + "  SELECT cs.ciccInvAccnt AS dbtKey, "
                + "         MAX(pn.cstapIpgPnN) AS cst_code, "
                + "         MAX(c.cstName) AS cst_name "
                + "  FROM " + q("yr") + " y "
                + "  JOIN " + q("cnInvCmmCst") + " cs ON cs.ciccCmmGr = y.yr_CmmGr AND cs.ciccType = 2 "
                + "  JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn "
                + "  JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta "
                + "  JOIN ags.cst c ON c.cstKey = ca.cstaCst "
                + "  WHERE y.yr_key = ? "
                + "  GROUP BY cs.ciccInvAccnt "
                + ") cy ON cy.dbtKey = f.dbtKey "
                + "LEFT JOIN ( "
                + "  SELECT cm.cnicInvAccnt AS dbtKey, "
                + "         MAX(CASE WHEN cm.cnicType = 8 THEN cm.cnicText END) AS curator_new, "
                + "         MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery_new "
                + "  FROM " + q("yr") + " y "
                + "  JOIN " + q("cnInvCmm") + " cm ON cm.cnicGroup = y.yr_CmmGr_New "
                + "  WHERE y.yr_key = ? AND y.yr_CmmGr_New IS NOT NULL "
                + "  GROUP BY cm.cnicInvAccnt "
                + ") cmn ON cmn.dbtKey = f.dbtKey "
                + "LEFT JOIN ( "
                + "  SELECT cs.ciccInvAccnt AS dbtKey, "
                + "         MAX(pn.cstapIpgPnN) AS cst_code_new "
                + "  FROM " + q("yr") + " y "
                + "  JOIN " + q("cnInvCmmCst") + " cs ON cs.ciccCmmGr = y.yr_CmmGr_New AND cs.ciccType = 2 "
                + "  JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn "
                + "  WHERE y.yr_key = ? AND y.yr_CmmGr_New IS NOT NULL "
                + "  GROUP BY cs.ciccInvAccnt "
                + ") cyn ON cyn.dbtKey = f.dbtKey "
                + "WHERE f.yr_key = ? "
                + "  AND (? IS NULL OR f.upl_date <= ( "
                + "        SELECT u.upl_date FROM " + q("cn_inv_dbt_upl") + " u WHERE u.upl_key = ? "
                + "      )) "
                + "ORDER BY f.dbtKey, f.upl_date, f.upl_key";

        log.log(Level.INFO, "Loading sudz Rslt portfolio for yr={0}, asOfUpl={1}",
                new Object[]{yrKey, asOfUpl});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrKey);
            statement.setInt(2, yrKey);
            statement.setInt(3, yrKey);
            statement.setInt(4, yrKey);
            statement.setInt(5, yrKey);
            if (asOfUpl == null) {
                statement.setNull(6, Types.INTEGER);
                statement.setNull(7, Types.INTEGER);
            } else {
                statement.setInt(6, asOfUpl);
                statement.setInt(7, asOfUpl);
            }
            try (ResultSet rs = statement.executeQuery()) {
                Map<Integer, Builder> builders = new LinkedHashMap<>();
                while (rs.next()) {
                    int dbtKey = rs.getInt("dbtKey");
                    Builder builder = builders.get(dbtKey);
                    if (builder == null) {
                        builder = new Builder(
                                dbtKey,
                                rs.getString("account_num"),
                                rs.getString("curator"),
                                rs.getString("mery"),
                                rs.getString("cst_code"),
                                rs.getString("cst_name"),
                                rs.getString("curator_new"),
                                rs.getString("mery_new"),
                                rs.getString("cst_code_new")
                        );
                        builders.put(dbtKey, builder);
                    }
                    BigDecimal overd = getBigDecimal(rs, "dvOverd");
                    if (builder.baseOverd == null) {
                        builder.baseOverd = overd;
                    }
                    /* Access: NULLIF(Overd(база)−ISNULL(Overd(d),0), 0); рост Overd не пишем. */
                    BigDecimal pogasheno = null;
                    if (builder.baseOverd != null && overd != null) {
                        BigDecimal delta = builder.baseOverd.subtract(overd);
                        if (delta.compareTo(BigDecimal.ZERO) > 0) {
                            pogasheno = delta;
                        }
                    }
                    builder.periods.add(new SudzRsltPeriod(
                            rs.getInt("upl_key"),
                            getLocalDate(rs, "upl_date"),
                            getLocalDate(rs, "as_of"),
                            rs.getString("invNumEnum"),
                            getInteger(rs, "idNum"),
                            rs.getString("cnNumEnum"),
                            getLocalDate(rs, "csoCnDate"),
                            getLong(rs, "org_id_value_l"),
                            rs.getString("ITN"),
                            rs.getString("CtptOrg"),
                            getLocalDate(rs, "dvDateMaturity"),
                            getBigDecimal(rs, "dvTtl"),
                            overd,
                            rs.getString("CstAgPnCode"),
                            rs.getString("CstAgPnName"),
                            rs.getString("AgOrg"),
                            pogasheno
                    ));
                }
                List<SudzRsltDebt> debts = new ArrayList<>(builders.size());
                for (Builder builder : builders.values()) {
                    debts.add(builder.buildCollapsed());
                }
                return List.copyOf(debts);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить портфель СУДЗ yr=" + yrKey, exception);
        }
    }

    @Override
    public List<SudzD644Row> findD644(int yrKey, int currUpl) {
        String call = "{call " + q("Yr_DbtChangesD644") + "(?, ?)}";
        log.log(Level.INFO, "EXEC {0}.Yr_DbtChangesD644 yr={1}, curr_upl={2}",
                new Object[]{schema, yrKey, currUpl});
        try (Connection connection = connectionFactory.createConnection();
             CallableStatement statement = connection.prepareCall(call)) {
            statement.setInt(1, yrKey);
            statement.setInt(2, currUpl);
            ResultSet rs = firstResultSet(statement);
            if (rs == null) {
                return List.of();
            }
            try (rs) {
                List<SudzD644Row> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(mapD644(rs));
                }
                return List.copyOf(rows);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить D644 yr=" + yrKey + ", currUpl=" + currUpl, exception);
        }
    }

    @Override
    public SudzSvodResult findD644Svod(int yrKey, int currUpl) {
        String call = "{call " + q("Yr_DbtChangesD644Svod") + "(?, ?)}";
        log.log(Level.INFO, "EXEC {0}.Yr_DbtChangesD644Svod yr={1}, curr_upl={2}",
                new Object[]{schema, yrKey, currUpl});
        try (Connection connection = connectionFactory.createConnection();
             CallableStatement statement = connection.prepareCall(call)) {
            statement.setInt(1, yrKey);
            statement.setInt(2, currUpl);
            List<SudzSvodAccount> accounts = new ArrayList<>();
            ResultSet first = firstResultSet(statement);
            if (first != null) {
                try (first) {
                    while (first.next()) {
                        accounts.add(new SudzSvodAccount(
                                first.getInt("№ счётов бухгалтерского учета"),
                                first.getString("Наименование счёта"),
                                getBigDecimal(first, "Сумма просроченной ДЗ на начало года"),
                                getBigDecimal(first, "Погашено просроченной ДЗ с начала года"),
                                getBigDecimal(first, "Остаток просроченной ДЗ портфеля"),
                                getDouble(first, "Погашено в %")
                        ));
                    }
                }
            }
            SudzSvodTotal total = null;
            if (statement.getMoreResults()) {
                try (ResultSet second = statement.getResultSet()) {
                    if (second != null && second.next()) {
                        total = new SudzSvodTotal(
                                getBigDecimal(second, "Сумма просроченной ДЗ на начало года"),
                                getBigDecimal(second, "Погашено просроченной ДЗ с начала года"),
                                getBigDecimal(second, "Остаток просроченной ДЗ портфеля"),
                                getDouble(second, "Погашено в %")
                        );
                    }
                }
            }
            return new SudzSvodResult(List.copyOf(accounts), total);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить свод D644 yr=" + yrKey + ", currUpl=" + currUpl, exception);
        }
    }

    @Override
    public SudzDebtCollection saveDebtCollection(
            int yrKey,
            int dbtKey,
            String curator,
            String mery,
            String cstCode
    ) {
        String curatorNorm = normalizeText(curator);
        String meryNorm = normalizeText(mery);
        String cstCodeNorm = normalizeText(cstCode);

        log.log(Level.INFO, "Saving sudz debt collection yr={0}, dbtKey={1}", new Object[]{yrKey, dbtKey});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzYear year = findYearOn(connection, yrKey)
                        .orElseThrow(() -> new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey));
                Integer cmmGr = year.cmmGr();
                if (cmmGr == null || cmmGr <= 0) {
                    throw new IllegalArgumentException("У года yr=" + yrKey + " не задана yr_CmmGr");
                }

                upsertComment(connection, cmmGr, dbtKey, CNIC_TYPE_CURATOR, curatorNorm);
                upsertComment(connection, cmmGr, dbtKey, CNIC_TYPE_MERY, meryNorm);
                String cstName = upsertCst(connection, cmmGr, dbtKey, cstCodeNorm);

                connection.commit();
                return new SudzDebtCollection(dbtKey, curatorNorm, meryNorm, cstCodeNorm, cstName, cmmGr);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось сохранить сбор СУДЗ yr=" + yrKey + ", dbtKey=" + dbtKey, exception);
        }
    }

    @Override
    public Optional<SudzDbtUplLauncher> findDbtUplLauncher(int uplKey) {
        log.log(Level.FINE, "Loading dbt upl launcher uplKey={0}", uplKey);
        try (Connection connection = connectionFactory.createConnection()) {
            Optional<SudzUplLookup> upl = findUplLookupOn(connection, uplKey);
            if (upl.isEmpty()) {
                return Optional.empty();
            }
            Optional<SudzDbtUplFile> file = findDbtUplFileByUpload(connection, uplKey);
            List<SudzDbtUplFileSh> sheets = List.of();
            List<SudzDbtUplInvDouble> invDoubles = List.of();
            List<SudzCnInvUplSfDouble> sfDoubles = List.of();
            List<SudzCnInvUplInvDbtDouble> invDbtDoubles = List.of();
            if (file.isPresent()) {
                int fileKey = file.get().cidufKey();
                sheets = loadDbtUplFileSheets(connection, fileKey);
                invDoubles = loadDbtUplInvDoubles(connection, fileKey);
            }
            sfDoubles = loadSfDoublesByUnload(connection, uplKey);
            invDbtDoubles = loadInvDbtDoublesByUnload(connection, uplKey);
            List<SudzCnInvUplDbtP1> dbtP1 = loadDbtP1ByUnload(connection, uplKey);
            return Optional.of(new SudzDbtUplLauncher(
                    upl.get(), file.orElse(null), sheets, invDoubles, sfDoubles, invDbtDoubles, dbtP1));
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить лаунчер загрузки свода uplKey=" + uplKey, exception);
        }
    }

    @Override
    public SudzDbtUplFile upsertDbtUplFile(int uplKey, String path, Boolean flLoad, Boolean flTbl) {
        log.log(Level.INFO, "Upsert CnInvDbtUplFile upload={0}", uplKey);
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ensureUplExists(connection, uplKey);
                Optional<SudzDbtUplFile> existing = findDbtUplFileByUpload(connection, uplKey);
                if (existing.isPresent()) {
                    SudzDbtUplFile cur = existing.get();
                    String newPath = path != null ? path.trim() : cur.cidufPath();
                    boolean newFlLoad = flLoad != null ? flLoad : cur.cidufFlLoad();
                    boolean newFlTbl = flTbl != null ? flTbl : cur.cidufFlTbl();
                    String sql = "UPDATE " + q("CnInvDbtUplFile")
                            + " SET cidufPath = ?, cidufFlLoad = ?, cidufFlTbl = ? WHERE cidufKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setString(1, newPath);
                        statement.setBoolean(2, newFlLoad);
                        statement.setBoolean(3, newFlTbl);
                        statement.setInt(4, cur.cidufKey());
                        statement.executeUpdate();
                    }
                } else {
                    String newPath = path != null ? path.trim() : "";
                    boolean newFlLoad = flLoad != null && flLoad;
                    boolean newFlTbl = flTbl != null && flTbl;
                    String sql = "INSERT INTO " + q("CnInvDbtUplFile")
                            + " (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)"
                            + " VALUES (?, ?, ?, NULL, ?)";
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setInt(1, uplKey);
                        statement.setString(2, newPath);
                        statement.setBoolean(3, newFlLoad);
                        statement.setBoolean(4, newFlTbl);
                        statement.executeUpdate();
                    }
                }
                connection.commit();
                return findDbtUplFileByUpload(connection, uplKey)
                        .orElseThrow(() -> new IllegalStateException(
                                "CnInvDbtUplFile не найден после upsert: uplKey=" + uplKey));
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось сохранить CnInvDbtUplFile uplKey=" + uplKey, exception);
        }
    }

    @Override
    public SudzDbtUplFile setDbtUplFileProgress(int uplKey, String progressHtml) {
        log.log(Level.INFO, "Set CnInvDbtUplFile progress upload={0}, len={1}",
                new Object[]{uplKey, progressHtml == null ? 0 : progressHtml.length()});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ensureUplExists(connection, uplKey);
                Optional<SudzDbtUplFile> existing = findDbtUplFileByUpload(connection, uplKey);
                if (existing.isEmpty()) {
                    String sql = "INSERT INTO " + q("CnInvDbtUplFile")
                            + " (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)"
                            + " VALUES (?, N'', 0, ?, 0)";
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setInt(1, uplKey);
                        statement.setString(2, progressHtml);
                        statement.executeUpdate();
                    }
                } else {
                    String sql = "UPDATE " + q("CnInvDbtUplFile")
                            + " SET cidufLoadingProgress = ? WHERE cidufKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setString(1, progressHtml);
                        statement.setInt(2, existing.get().cidufKey());
                        statement.executeUpdate();
                    }
                }
                connection.commit();
                return findDbtUplFileByUpload(connection, uplKey)
                        .orElseThrow(() -> new IllegalStateException(
                                "CnInvDbtUplFile не найден после setProgress: uplKey=" + uplKey));
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось записать cidufLoadingProgress uplKey=" + uplKey, exception);
        }
    }

    @Override
    public int replaceDbtUplTbl(int unloadKey, List<SudzDbtUplTblRow> rows) {
        Objects.requireNonNull(rows, "rows");
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        log.log(Level.INFO, "Replace CnInvDbtUplTbl unloadKey={0}, rows={1}",
                new Object[]{unloadKey, rows.size()});
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                clearDbtUplTblDependents(connection, unloadKey);
                String deleteSql = "DELETE FROM " + q("CnInvDbtUplTbl") + " WHERE cidutUnloadKey = ?";
                try (PreparedStatement delete = connection.prepareStatement(deleteSql)) {
                    delete.setInt(1, unloadKey);
                    delete.executeUpdate();
                }
                if (!rows.isEmpty()) {
                    String insertSql = "INSERT INTO " + q("CnInvDbtUplTbl") + " ("
                            + "FindDbtNum, cidutAccount, cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN,"
                            + " cidutCnName, cidutCnDate, cidutCnInv, cidutFormtnDate, cidutMatrtyDate,"
                            + " cidutDebt, cidutDebtOverdue, cidutDoc, cidutLink,"
                            + " cidutSheet, cidutSheetNum, cidutUnloadKey"
                            + ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
                    try (PreparedStatement insert = connection.prepareStatement(insertSql)) {
                        int batch = 0;
                        for (SudzDbtUplTblRow row : rows) {
                            bindTblRow(insert, row);
                            insert.addBatch();
                            batch++;
                            if (batch % 500 == 0) {
                                insert.executeBatch();
                            }
                        }
                        insert.executeBatch();
                    }
                }
                connection.commit();
                return rows.size();
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось заменить CnInvDbtUplTbl unloadKey=" + unloadKey, exception);
        }
    }

    /**
     * Очищает очереди и P1, ссылающиеся на строки Tbl, перед {@link #replaceDbtUplTbl}.
     * Иначе DELETE Tbl падает на FK (P1, КСДСФ, КСДД).
     *
     * @param connection активное соединение (транзакция вызывающего)
     * @param unloadKey ключ выгрузки
     */
    private void clearDbtUplTblDependents(Connection connection, int unloadKey) throws SQLException {
        clearDbtUplFunnelQueuesOnConnection(connection, unloadKey, unloadKey);
    }

    /**
     * Сброс очередей воронки и scratch-буферов для выгрузки (один connection).
     *
     * @param connection JDBC-соединение
     * @param unloadKey {@code upl_key}
     * @param fileKey ключ File для FileInvDouble (обычно = uplKey)
     * @return счётчики DELETE
     * @throws SQLException при ошибке SQL
     */
    private SudzDbtUplFunnelQueueClearResult clearDbtUplFunnelQueuesOnConnection(
            Connection connection,
            int unloadKey,
            int fileKey
    ) throws SQLException {
        String p1 = q("CnInvUplDbtP1");
        String invDbtDouble = q("CnInvUplInvDbtDouble");
        String sfDouble = q("CnInvUplSfDouble");
        String fileInvDouble = q("CnInvDbtUplFileInvDouble");
        String tblCnInv = q("CnInvDbtUplTblCnInv");

        int p1Deleted = 0;
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM " + p1 + " WHERE cip1UnloadKey = ?")) {
            ps.setInt(1, unloadKey);
            p1Deleted = ps.executeUpdate();
        } catch (SQLException exception) {
            if (!isMissingTable(exception, "CnInvUplDbtP1")) {
                throw exception;
            }
        }

        int invDbtDeleted;
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM " + invDbtDouble + " WHERE ciudUnloadKey = ?")) {
            ps.setInt(1, unloadKey);
            invDbtDeleted = ps.executeUpdate();
        }

        int sfDeleted;
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM " + sfDouble + " WHERE ciusUnloadKey = ?")) {
            ps.setInt(1, unloadKey);
            sfDeleted = ps.executeUpdate();
        }

        int fileInvDeleted;
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM " + fileInvDouble + " WHERE cidufiCiduf = ?")) {
            ps.setInt(1, fileKey);
            fileInvDeleted = ps.executeUpdate();
        }

        int tblCnInvDeleted;
        try (PreparedStatement ps = connection.prepareStatement("DELETE FROM " + tblCnInv)) {
            tblCnInvDeleted = ps.executeUpdate();
        }

        log.log(Level.INFO,
                "clearDbtUplFunnelQueues uplKey={0} fileKey={1} sf={2} invDbt={3} fileInv={4} tblCnInv={5} p1={6}",
                new Object[]{unloadKey, fileKey, sfDeleted, invDbtDeleted, fileInvDeleted, tblCnInvDeleted, p1Deleted});
        return new SudzDbtUplFunnelQueueClearResult(
                sfDeleted, invDbtDeleted, fileInvDeleted, tblCnInvDeleted, p1Deleted);
    }

    @Override
    public SudzDbtUplFunnelQueueClearResult clearDbtUplFunnelQueues(int unloadKey, Integer fileKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        int resolvedFileKey = fileKey != null && fileKey > 0 ? fileKey : unloadKey;
        try (Connection connection = connectionFactory.createConnection()) {
            return clearDbtUplFunnelQueuesOnConnection(connection, unloadKey, resolvedFileKey);
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось очистить очереди воронки unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public int countDbtUplTbl(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String sql = "SELECT COUNT(*) FROM " + q("CnInvDbtUplTbl") + " WHERE cidutUnloadKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return 0;
                }
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            throw wrap("Не удалось посчитать CnInvDbtUplTbl unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public List<SudzDbtUplOrgNotInBuirg> findDbtUplOrgNotInBuirg(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String sql = "SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, w.ogNm "
                + "FROM ( "
                + "  SELECT t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN "
                + "  FROM " + tbl + " AS t "
                + "  WHERE t.cidutUnloadKey = ? "
                + "  GROUP BY t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN "
                + ") AS z "
                + "LEFT JOIN ( "
                + "  SELECT i.org_id_value_l, i.org_id_key "
                + "  FROM ags.org_id AS i "
                + "  WHERE i.org_id_type = 1 "
                + ") AS x ON z.cidutCntrPrtNum = x.org_id_value_l "
                + "LEFT JOIN ( "
                + "  SELECT i.org_id_value_t, o.ogNm "
                + "  FROM ags.org_id AS i "
                + "  INNER JOIN ags.og AS o ON i.org = o.ogKey "
                + "  WHERE i.org_id_type = 2 "
                + ") AS w ON z.cidutCntrPrtITN = w.org_id_value_t "
                + "WHERE x.org_id_key IS NULL "
                + "ORDER BY z.cidutCntrPrtNum";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplOrgNotInBuirg> rows = new ArrayList<>();
                while (rs.next()) {
                    Integer buirg = (Integer) rs.getObject("cidutCntrPrtNum");
                    rows.add(new SudzDbtUplOrgNotInBuirg(
                            buirg,
                            rs.getNString("cidutCntrPrtName"),
                            rs.getNString("cidutCntrPrtITN"),
                            rs.getNString("ogNm")
                    ));
                }
                return List.copyOf(rows);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать orgNotInBuirg unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public List<SudzDbtUplCnNotLoad> findDbtUplCnNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        // *Null — как вычисляемые поля Access CnInvDbtUplTbl (не физические столбцы sudz).
        String sql = ""
                + "WITH norm AS ( "
                + "  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN, "
                + "         a.cidutCnName, a.cidutCnDate, "
                + "         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull "
                + "  FROM " + tbl + " AS a "
                + "  WHERE a.cidutUnloadKey = ? "
                + "), "
                + "ctptNot AS ( "
                + "  SELECT z.cidutCntrPrtNum "
                + "  FROM ( "
                + "    SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "    FROM " + tbl + " "
                + "    WHERE cidutUnloadKey = ? "
                + "    GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "  ) AS z "
                + "  LEFT JOIN ags.org_id AS x "
                + "    ON z.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1 "
                + "  WHERE x.org_id_key IS NULL "
                + "), "
                + "tblCtptExist AS ( "
                + "  SELECT DISTINCT "
                + "    n.cidutCntrPrtNum, og.ogNm AS cidutCntrPrtName, n.cidutCntrPrtITN, "
                + "    n.cidutCnName, n.cidutCnDate, n.cidutCnDateNull, n.cidutCnNameNull "
                + "  FROM norm AS n "
                + "  LEFT JOIN ctptNot AS b ON n.cidutCntrPrtNum = b.cidutCntrPrtNum "
                + "  INNER JOIN ags.org_id AS oi "
                + "    ON n.cidutCntrPrtNum = oi.org_id_value_l AND oi.org_id_type = 1 "
                + "  LEFT JOIN ags.og AS og ON oi.org = og.ogKey "
                + "  WHERE b.cidutCntrPrtNum IS NULL "
                + "), "
                + "cnCtptList AS ( "
                + "  SELECT c.cn_key, num.cnnNumNull AS cn_number, i.org_id_value_l, "
                + "         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull "
                + "  FROM ags.cn AS c "
                + "  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2 "
                + "  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s "
                + "  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl "
                + "  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key "
                + "  INNER JOIN ags.cnNum AS num ON c.cn_key = num.cnnCn "
                + "), "
                + "cnCtptExistNot AS ( "
                + "  SELECT DISTINCT "
                + "    k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, "
                + "    k.cidutCnName, k.cidutCnDate, k.cidutCnDateNull, k.cidutCnNameNull "
                + "  FROM tblCtptExist AS k "
                + "  LEFT JOIN cnCtptList AS l "
                + "    ON k.cidutCnNameNull = l.cn_number "
                + "   AND k.cidutCntrPrtNum = l.org_id_value_l "
                + "   AND k.cidutCnDateNull = l.csoCnDateNull "
                + "  WHERE l.cn_key IS NULL "
                + "), "
                + "cnNumNotLoad AS ( "
                + "  SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, "
                + "         z.cidutCnNameNull AS cidutCnName, z.cidutCnDateNull AS cidutCnDate, "
                + "         COUNT(y.cn_key) AS cnCount "
                + "  FROM cnCtptExistNot AS z "
                + "  LEFT JOIN ( "
                + "    SELECT n.cnnNumNull AS cn_number, o.cn_key "
                + "    FROM ags.cn AS o "
                + "    INNER JOIN ags.cnNum AS n ON o.cn_key = n.cnnCn "
                + "  ) AS y ON z.cidutCnNameNull = y.cn_number "
                + "  GROUP BY z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, "
                + "           z.cidutCnNameNull, z.cidutCnDateNull "
                + "  HAVING COUNT(y.cn_key) = 0 "
                + ") "
                + "SELECT d.cidutCntrPrtNum, x.org_id_key, d.cidutCntrPrtName, d.cidutCntrPrtITN, "
                + "       d.cidutCnName, d.cidutCnDate, d.cnCount, e.countCnName "
                + "FROM cnNumNotLoad AS d "
                + "LEFT JOIN ( "
                + "  SELECT cidutCnName, COUNT(*) AS countCnName "
                + "  FROM cnNumNotLoad "
                + "  GROUP BY cidutCnName "
                + ") AS e ON d.cidutCnName = e.cidutCnName "
                + "LEFT JOIN ags.org_id AS x "
                + "  ON d.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1 "
                + "ORDER BY d.cidutCntrPrtNum, d.cidutCnName";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            statement.setInt(2, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplCnNotLoad> rows = new ArrayList<>();
                while (rs.next()) {
                    Integer buirg = (Integer) rs.getObject("cidutCntrPrtNum");
                    Integer orgIdKey = (Integer) rs.getObject("org_id_key");
                    int cnCount = rs.getInt("cnCount");
                    int countCnName = rs.getInt("countCnName");
                    rows.add(new SudzDbtUplCnNotLoad(
                            buirg,
                            orgIdKey,
                            rs.getNString("cidutCntrPrtName"),
                            rs.getNString("cidutCntrPrtITN"),
                            rs.getNString("cidutCnName"),
                            getLocalDate(rs, "cidutCnDate"),
                            cnCount,
                            countCnName
                    ));
                }
                return List.copyOf(rows);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать CnNotLoad unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public List<SudzDbtUplCnExistCtptNotLoad> findDbtUplCnExistCtptNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        // Та же цепочка, что CnNotLoad, но HAVING COUNT(y.cn_key) > 0 (номер уже в БД).
        String sql = ""
                + "WITH norm AS ( "
                + "  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN, "
                + "         a.cidutCnName, a.cidutCnDate, "
                + "         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull "
                + "  FROM " + tbl + " AS a "
                + "  WHERE a.cidutUnloadKey = ? "
                + "), "
                + "ctptNot AS ( "
                + "  SELECT z.cidutCntrPrtNum "
                + "  FROM ( "
                + "    SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "    FROM " + tbl + " "
                + "    WHERE cidutUnloadKey = ? "
                + "    GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "  ) AS z "
                + "  LEFT JOIN ags.org_id AS x "
                + "    ON z.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1 "
                + "  WHERE x.org_id_key IS NULL "
                + "), "
                + "tblCtptExist AS ( "
                + "  SELECT DISTINCT "
                + "    n.cidutCntrPrtNum, og.ogNm AS cidutCntrPrtName, n.cidutCntrPrtITN, "
                + "    n.cidutCnName, n.cidutCnDate, n.cidutCnDateNull, n.cidutCnNameNull "
                + "  FROM norm AS n "
                + "  LEFT JOIN ctptNot AS b ON n.cidutCntrPrtNum = b.cidutCntrPrtNum "
                + "  INNER JOIN ags.org_id AS oi "
                + "    ON n.cidutCntrPrtNum = oi.org_id_value_l AND oi.org_id_type = 1 "
                + "  LEFT JOIN ags.og AS og ON oi.org = og.ogKey "
                + "  WHERE b.cidutCntrPrtNum IS NULL "
                + "), "
                + "cnCtptList AS ( "
                + "  SELECT c.cn_key, num.cnnNumNull AS cn_number, i.org_id_value_l, "
                + "         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull "
                + "  FROM ags.cn AS c "
                + "  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2 "
                + "  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s "
                + "  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl "
                + "  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key "
                + "  INNER JOIN ags.cnNum AS num ON c.cn_key = num.cnnCn "
                + "), "
                + "cnCtptExistNot AS ( "
                + "  SELECT DISTINCT "
                + "    k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, "
                + "    k.cidutCnName, k.cidutCnDate, k.cidutCnDateNull, k.cidutCnNameNull "
                + "  FROM tblCtptExist AS k "
                + "  LEFT JOIN cnCtptList AS l "
                + "    ON k.cidutCnNameNull = l.cn_number "
                + "   AND k.cidutCntrPrtNum = l.org_id_value_l "
                + "   AND k.cidutCnDateNull = l.csoCnDateNull "
                + "  WHERE l.cn_key IS NULL "
                + ") "
                + "SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, "
                + "       z.cidutCnNameNull AS cidutCnName, z.cidutCnDateNull AS cidutCnDate, "
                + "       COUNT(y.cn_key) AS cnCount "
                + "FROM cnCtptExistNot AS z "
                + "LEFT JOIN ( "
                + "  SELECT n.cnnNumNull AS cn_number, o.cn_key "
                + "  FROM ags.cn AS o "
                + "  INNER JOIN ags.cnNum AS n ON o.cn_key = n.cnnCn "
                + ") AS y ON z.cidutCnNameNull = y.cn_number "
                + "GROUP BY z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, "
                + "         z.cidutCnNameNull, z.cidutCnDateNull "
                + "HAVING COUNT(y.cn_key) > 0 "
                + "ORDER BY z.cidutCntrPrtNum, z.cidutCnNameNull";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            statement.setInt(2, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplCnExistCtptNotLoad> rows = new ArrayList<>();
                while (rs.next()) {
                    Integer buirg = (Integer) rs.getObject("cidutCntrPrtNum");
                    rows.add(new SudzDbtUplCnExistCtptNotLoad(
                            buirg,
                            rs.getNString("cidutCntrPrtName"),
                            rs.getNString("cidutCntrPrtITN"),
                            rs.getNString("cidutCnName"),
                            getLocalDate(rs, "cidutCnDate"),
                            rs.getInt("cnCount")
                    ));
                }
                return List.copyOf(rows);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать CnExistCtptNotLoad unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplCnNotLoadApplyResult applyDbtUplCnNotLoad(
            List<SudzDbtUplCnNotLoad> rows,
            int cnMark,
            String note
    ) {
        Objects.requireNonNull(rows, "rows");
        Objects.requireNonNull(note, "note");
        if (cnMark <= 0) {
            throw new IllegalArgumentException("cnMark должен быть положительным: " + cnMark);
        }
        Map<Integer, SudzDbtUplCnNotLoadInserted> inserted = new LinkedHashMap<>();
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int index = 1;
                for (SudzDbtUplCnNotLoad row : rows) {
                    if (row.countCnName() == 1) {
                        if (row.orgIdKey() == null || row.orgIdKey() <= 0) {
                            throw new IllegalArgumentException(
                                    "org_id_key обязателен для INSERT договора, строка " + index
                            );
                        }
                        if (row.cnName() == null || row.cnName().isBlank()) {
                            throw new IllegalArgumentException(
                                    "номер договора пуст, строка " + index
                            );
                        }
                        inserted.put(index, insertCnNotLoadChain(connection, row, cnMark, note, now));
                    }
                    index++;
                }
                connection.commit();
                log.log(Level.INFO, "CnNotLoad apply cnMark={0} inserted={1}",
                        new Object[]{cnMark, inserted.size()});
                return new SudzDbtUplCnNotLoadApplyResult(cnMark, note, inserted, inserted.size());
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply CnNotLoad cnMark=" + cnMark, exception);
        }
    }

    @Override
    public int rollbackCnNotLoadByMark(int cnMark) {
        if (cnMark <= 0) {
            throw new IllegalArgumentException("cnMark должен быть положительным: " + cnMark);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                String cnKeys = "SELECT cn_key FROM ags.cn WHERE cnMark = ?";
                try (PreparedStatement delOrg = connection.prepareStatement(
                        "DELETE FROM ags.cn_s_org WHERE csoCn_s_org_smpl IN ("
                                + "SELECT m.csosKey FROM ags.cn_s_org_smpl AS m "
                                + "INNER JOIN ags.cn_s AS s ON m.csosCn_s = s.cn_s_key "
                                + "WHERE s.cn_key IN (" + cnKeys + "))")) {
                    delOrg.setInt(1, cnMark);
                    delOrg.executeUpdate();
                }
                try (PreparedStatement delSmpl = connection.prepareStatement(
                        "DELETE FROM ags.cn_s_org_smpl WHERE csosCn_s IN ("
                                + "SELECT cn_s_key FROM ags.cn_s WHERE cn_key IN (" + cnKeys + "))")) {
                    delSmpl.setInt(1, cnMark);
                    delSmpl.executeUpdate();
                }
                try (PreparedStatement delS = connection.prepareStatement(
                        "DELETE FROM ags.cn_s WHERE cn_key IN (" + cnKeys + ")")) {
                    delS.setInt(1, cnMark);
                    delS.executeUpdate();
                }
                try (PreparedStatement delNum = connection.prepareStatement(
                        "DELETE FROM ags.cnNum WHERE cnnCn IN (" + cnKeys + ")")) {
                    delNum.setInt(1, cnMark);
                    delNum.executeUpdate();
                }
                int deletedCn;
                try (PreparedStatement delCn = connection.prepareStatement(
                        "DELETE FROM ags.cn WHERE cnMark = ?")) {
                    delCn.setInt(1, cnMark);
                    deletedCn = delCn.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "CnNotLoad rollback cnMark={0} deletedCn={1}",
                        new Object[]{cnMark, deletedCn});
                return deletedCn;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось откатить CnNotLoad cnMark=" + cnMark, exception);
        }
    }

    @Override
    public int clearDbtUplInvDouble() {
        String sql = "DELETE FROM " + q("CnInvDbtUplFileInvDouble");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int deleted = statement.executeUpdate();
            log.log(Level.INFO, "clearDbtUplInvDouble deleted={0}", deleted);
            return deleted;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось очистить CnInvDbtUplFileInvDouble", exception);
        }
    }

    @Override
    public SudzDbtUplCnCtptExistInvResult rebuildDbtUplCnCtptExistInvNot(int unloadKey, Integer fileKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String buf = q("CnInvDbtUplTblCnInv");
        String invDouble = q("CnInvDbtUplFileInvDouble");
        long t0 = System.nanoTime();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                try (PreparedStatement del = connection.prepareStatement("DELETE FROM " + buf)) {
                    del.executeUpdate();
                }

                // Этапы на #temp: быстрее одного огромного CTE (UAT: ~3 мин → секунды).
                try (Statement ddl = connection.createStatement()) {
                    ddl.execute("IF OBJECT_ID('tempdb..#ciduNorm') IS NOT NULL DROP TABLE #ciduNorm");
                    ddl.execute("IF OBJECT_ID('tempdb..#ciduMatched') IS NOT NULL DROP TABLE #ciduMatched");
                    ddl.execute("IF OBJECT_ID('tempdb..#ciduPairs') IS NOT NULL DROP TABLE #ciduPairs");
                    // COLLATE как у ags/sudz: иначе tempdb (Latin1) ломает JOIN с Cyrillic_General_CI_AS.
                    ddl.execute(
                            "CREATE TABLE #ciduNorm ("
                                    + " cidutCntrPrtNum int NULL,"
                                    + " cidutCnDateNull date NOT NULL,"
                                    + " cidutCnNameNull nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL,"
                                    + " cidutCnInvNull nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL)"
                    );
                    ddl.execute(
                            "CREATE TABLE #ciduMatched ("
                                    + " cidutCntrPrtNum int NULL,"
                                    + " cidutCnDateNull date NOT NULL,"
                                    + " cidutCnNameNull nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL,"
                                    + " cn_key int NOT NULL)"
                    );
                    ddl.execute(
                            "CREATE TABLE #ciduPairs ("
                                    + " cn_key int NOT NULL,"
                                    + " cidutCnNameNull nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL,"
                                    + " cidutCnInvNull nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL)"
                    );
                }

                String fillNorm = ""
                        + "INSERT INTO #ciduNorm (cidutCntrPrtNum, cidutCnDateNull, cidutCnNameNull, cidutCnInvNull) "
                        + "SELECT a.cidutCntrPrtNum, "
                        + "  CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                        + "       ELSE CAST(a.cidutCnDate AS date) END, "
                        + "  CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                        + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END, "
                        + "  CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                        + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END "
                        + "FROM " + tbl + " AS a "
                        + "WHERE a.cidutUnloadKey = ? "
                        + "  AND EXISTS ("
                        + "    SELECT 1 FROM ags.org_id AS oi "
                        + "    WHERE oi.org_id_value_l = a.cidutCntrPrtNum AND oi.org_id_type = 1"
                        + "  )";
                try (PreparedStatement ps = connection.prepareStatement(fillNorm)) {
                    ps.setInt(1, unloadKey);
                    ps.executeUpdate();
                }
                try (Statement idx = connection.createStatement()) {
                    idx.execute("CREATE INDEX IX_ciduNorm_keys ON #ciduNorm"
                            + " (cidutCntrPrtNum, cidutCnNameNull, cidutCnDateNull)");
                    idx.execute("CREATE INDEX IX_ciduNorm_inv ON #ciduNorm (cidutCnInvNull)");
                }

                String fillMatched = ""
                        + "INSERT INTO #ciduMatched (cidutCntrPrtNum, cidutCnDateNull, cidutCnNameNull, cn_key) "
                        + "SELECT DISTINCT n.cidutCntrPrtNum, n.cidutCnDateNull, n.cidutCnNameNull, c.cn_key "
                        + "FROM #ciduNorm AS n "
                        + "INNER JOIN ags.cnNum AS num ON num.cnnNumNull = n.cidutCnNameNull "
                        + "INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn "
                        + "INNER JOIN ags.cn_s AS s ON s.cn_key = c.cn_key AND s.cn_s_type = 2 "
                        + "INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key "
                        + "INNER JOIN ags.cn_s_org AS o ON o.csoCn_s_org_smpl = m.csosKey "
                        + "INNER JOIN ags.org_id AS i ON i.org_id_key = m.csosOrgId "
                        + "  AND i.org_id_value_l = n.cidutCntrPrtNum "
                        + "WHERE (CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                        + "            ELSE CAST(o.csoCnDate AS date) END) = n.cidutCnDateNull";
                try (PreparedStatement ps = connection.prepareStatement(fillMatched)) {
                    ps.executeUpdate();
                }
                try (Statement idx = connection.createStatement()) {
                    idx.execute("CREATE INDEX IX_ciduMatched ON #ciduMatched"
                            + " (cidutCntrPrtNum, cidutCnNameNull, cidutCnDateNull)");
                    idx.execute("CREATE INDEX IX_ciduMatched_cn ON #ciduMatched (cn_key)");
                }

                String fillPairs = ""
                        + "INSERT INTO #ciduPairs (cn_key, cidutCnNameNull, cidutCnInvNull) "
                        + "SELECT DISTINCT m.cn_key, m.cidutCnNameNull, n.cidutCnInvNull "
                        + "FROM #ciduMatched AS m "
                        + "INNER JOIN #ciduNorm AS n "
                        + "  ON n.cidutCntrPrtNum = m.cidutCntrPrtNum "
                        + " AND n.cidutCnNameNull = m.cidutCnNameNull "
                        + " AND n.cidutCnDateNull = m.cidutCnDateNull";
                try (PreparedStatement ps = connection.prepareStatement(fillPairs)) {
                    ps.executeUpdate();
                }
                try (Statement idx = connection.createStatement()) {
                    idx.execute("CREATE INDEX IX_ciduPairs ON #ciduPairs (cn_key, cidutCnInvNull)");
                }

                String insertMissing = ""
                        + "INSERT INTO " + buf
                        + " (cidutciCn_key, cidutciCnName, cidutciCnInv, inNumCount) "
                        + "SELECT p.cn_key, p.cidutCnNameNull, p.cidutCnInvNull, cnt.inNumCount "
                        + "FROM #ciduPairs AS p "
                        + "LEFT JOIN ("
                        + "  SELECT ci.ciCn AS cn_key, n.inNumNull, n.inNum "
                        + "  FROM ags.cnInv AS ci "
                        + "  INNER JOIN #ciduMatched AS m ON m.cn_key = ci.ciCn "
                        + "  INNER JOIN ags.invNum AS n ON n.inInv = ci.ciInv "
                        + "  GROUP BY ci.ciCn, n.inNumNull, n.inNum"
                        + ") AS g ON g.cn_key = p.cn_key "
                        + " AND (g.inNumNull = p.cidutCnInvNull "
                        + "      OR (p.cidutCnInvNull <> N'NullИлиПусто' "
                        + "          AND g.inNum LIKE p.cidutCnInvNull + N' %')) "
                        + "LEFT JOIN ("
                        + "  SELECT n.inNumNull, COUNT(DISTINCT n.inInv) AS inNumCount "
                        + "  FROM ags.invNum AS n "
                        + "  INNER JOIN (SELECT DISTINCT cidutCnInvNull FROM #ciduPairs) AS x "
                        + "    ON x.cidutCnInvNull = n.inNumNull "
                        + "  GROUP BY n.inNumNull"
                        + ") AS cnt ON cnt.inNumNull = p.cidutCnInvNull "
                        + "WHERE g.cn_key IS NULL";
                int inserted;
                try (PreparedStatement ps = connection.prepareStatement(insertMissing)) {
                    inserted = ps.executeUpdate();
                }
                long tSql = System.nanoTime();

                List<SudzDbtUplCnCtptExistInvContract> contracts = loadCnCtptExistInvContracts(connection, buf);

                if (fileKey != null && fileKey > 0) {
                    insertInvDoubleBatch(connection, invDouble, fileKey, contracts);
                    rebuildDbtSfDoubleQueue(connection, tbl, buf, unloadKey, fileKey);
                }

                connection.commit();
                long tEnd = System.nanoTime();
                log.log(Level.INFO,
                        "rebuildDbtUplCnCtptExistInvNot unloadKey={0} rows={1} contracts={2}"
                                + " sqlMs={3} totalMs={4}",
                        new Object[]{
                                unloadKey,
                                inserted,
                                contracts.size(),
                                (tSql - t0) / 1_000_000L,
                                (tEnd - t0) / 1_000_000L
                        });
                return new SudzDbtUplCnCtptExistInvResult(inserted, contracts);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось пересобрать CnInvDbtUplTblCnInv unloadKey=" + unloadKey, exception);
        }
    }

    /**
     * Пакетная запись очереди InvDouble (как {@code CnInvConcat} при {@code inNumCount}).
     */
    private static void insertInvDoubleBatch(
            Connection connection,
            String invDouble,
            int fileKey,
            List<SudzDbtUplCnCtptExistInvContract> contracts
    ) throws SQLException {
        String sql = "INSERT INTO " + invDouble
                + " (cidufiCiduf, cidufiCnNnn, cidufiCnNum, cidufiCnKey,"
                + " cidufiInvNnn, cidufiInvNum, cidufiInvNumCount)"
                + " VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement dbl = connection.prepareStatement(sql)) {
            int cnNnn = 1;
            int batch = 0;
            for (SudzDbtUplCnCtptExistInvContract contract : contracts) {
                int invNnn = 1;
                for (SudzDbtUplCnCtptExistInvItem item : contract.invoices()) {
                    if (item.inNumCount() != null) {
                        dbl.setInt(1, fileKey);
                        dbl.setInt(2, cnNnn);
                        dbl.setNString(3, contract.cnName());
                        dbl.setInt(4, contract.cnKey());
                        dbl.setInt(5, invNnn);
                        if (item.cnInv() == null || item.cnInv().isBlank()
                                || "NullИлиПусто".equals(item.cnInv())) {
                            dbl.setNull(6, Types.NVARCHAR);
                        } else {
                            dbl.setNString(6, item.cnInv());
                        }
                        dbl.setNString(7, String.valueOf(item.inNumCount()));
                        dbl.addBatch();
                        batch++;
                        if (batch >= 200) {
                            dbl.executeBatch();
                            batch = 0;
                        }
                    }
                    invNnn++;
                }
                cnNnn++;
            }
            if (batch > 0) {
                dbl.executeBatch();
            }
        }
    }

    /**
     * A2.1c: alias {@code invNum} на hist-iKey договора вместо нового {@code ags.inv},
     * если на {@code cn_key} уже есть СФ с extended/prefix совпадением.
     *
     * @param connection JDBC
     * @param cnKey ключ договора
     * @param cnInv номер СФ из Tbl
     * @param now метка времени
     * @return {@code true} если alias добавлен (новый inv не нужен)
     * @throws SQLException при ошибке SQL
     */
    private boolean tryInsertInvNumAliasOnCn(
            Connection connection,
            int cnKey,
            String cnInv,
            Timestamp now
    ) throws SQLException {
        if (cnInv == null || cnInv.isBlank() || "NullИлиПусто".equals(cnInv)) {
            return false;
        }
        String trimmed = cnInv.trim();
        String findHist = ""
                + "SELECT TOP 1 ci.ciInv AS iKey "
                + "FROM ags.cnInv AS ci "
                + "INNER JOIN ags.invNum AS n ON n.inInv = ci.ciInv "
                + "WHERE ci.ciCn = ? "
                + "  AND (n.inNumNull = ? OR n.inNum LIKE ? + N' %') "
                + "ORDER BY ci.ciInv";
        Integer histIKey = null;
        try (PreparedStatement ps = connection.prepareStatement(findHist)) {
            ps.setInt(1, cnKey);
            ps.setNString(2, trimmed);
            ps.setNString(3, trimmed);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    histIKey = rs.getInt("iKey");
                }
            }
        }
        if (histIKey == null) {
            return false;
        }
        String insertAlias = ""
                + "INSERT INTO ags.invNum (inNum, inInv, inTimeOfEntry) "
                + "SELECT ?, ?, ? "
                + "WHERE NOT EXISTS ( "
                + "  SELECT 1 FROM ags.invNum AS n "
                + "  WHERE n.inInv = ? "
                + "    AND LTRIM(RTRIM(ISNULL(n.inNum, N''))) = ? "
                + ")";
        try (PreparedStatement ps = connection.prepareStatement(insertAlias)) {
            ps.setNString(1, trimmed);
            ps.setInt(2, histIKey);
            ps.setTimestamp(3, now);
            ps.setInt(4, histIKey);
            ps.setNString(5, trimmed);
            int n = ps.executeUpdate();
            if (n > 0) {
                log.log(Level.INFO,
                        "tryInsertInvNumAliasOnCn cnKey={0} iKey={1} inNum={2}",
                        new Object[]{cnKey, histIKey, trimmed});
            }
            return true;
        }
    }

    @Override
    public SudzDbtUplCnCtptExistInvApplyResult applyDbtUplCnCtptExistInvNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String buf = q("CnInvDbtUplTblCnInv");
        String select = "SELECT cidutciCn_key, cidutciCnInv FROM " + buf
                + " WHERE inNumCount IS NULL"
                + " ORDER BY cidutciCn_key, cidutciRow";
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int inserted = 0;
                int aliasOnly = 0;
                try (PreparedStatement statement = connection.prepareStatement(select);
                     ResultSet rs = statement.executeQuery()) {
                    while (rs.next()) {
                        int cnKey = rs.getInt("cidutciCn_key");
                        String cnInv = rs.getNString("cidutciCnInv");
                        if (tryInsertInvNumAliasOnCn(connection, cnKey, cnInv, now)) {
                            aliasOnly++;
                            continue;
                        }
                        int invKey;
                        try (PreparedStatement inv = connection.prepareStatement(
                                "INSERT INTO ags.inv (iTimeOfEntry) VALUES (?)",
                                Statement.RETURN_GENERATED_KEYS)) {
                            inv.setTimestamp(1, now);
                            inv.executeUpdate();
                            invKey = readGeneratedKey(inv, "Не удалось получить iKey");
                        }
                        try (PreparedStatement invNum = connection.prepareStatement(
                                "INSERT INTO ags.invNum (inNum, inInv, inTimeOfEntry) VALUES (?, ?, ?)")) {
                            if (cnInv == null || cnInv.isBlank() || "NullИлиПусто".equals(cnInv)) {
                                invNum.setNull(1, Types.NVARCHAR);
                            } else {
                                invNum.setNString(1, cnInv);
                            }
                            invNum.setInt(2, invKey);
                            invNum.setTimestamp(3, now);
                            invNum.executeUpdate();
                        }
                        try (PreparedStatement cnInvPs = connection.prepareStatement(
                                "INSERT INTO ags.cnInv (ciInv, ciCn, ciTimeOfEntry) VALUES (?, ?, ?)")) {
                            cnInvPs.setInt(1, invKey);
                            cnInvPs.setInt(2, cnKey);
                            cnInvPs.setTimestamp(3, now);
                            cnInvPs.executeUpdate();
                        }
                        inserted++;
                    }
                }
                connection.commit();
                log.log(Level.INFO,
                        "applyDbtUplCnCtptExistInvNotLoad unloadKey={0} inserted={1} aliasOnly={2}",
                        new Object[]{unloadKey, inserted, aliasOnly});
                return new SudzDbtUplCnCtptExistInvApplyResult(inserted);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply CnCtptExistInvNotLoad unloadKey=" + unloadKey, exception);
        }
    }

    /**
     * CTE {@code ciduCnCtptInvAccSmplNot}: ExistList → ExistInvAll → AccSmplAll
     * → {@code ciasKey IS NULL}. Anti-join Smpl: ({@code ciKey}, {@code account_key}, БУиРГ),
     * не {@code csosKey}. {@code cidutAccount} = {@code account_key}.
     * Tbl фильтруется {@code cidutUnloadKey} (в Access буфер один пакет).
     *
     * @param tbl квалифицированное имя {@code CnInvDbtUplTbl}
     * @return SQL с одним {@code ?} = unloadKey; финальный CTE {@code accSmplNot}
     */
    /**
     * A2.1: выбор {@code invNumKey} для {@code invDbtVar} — текст Tbl на том же {@code iKey},
     * не hist-ranking сущности (он в {@link #fillSudzEiaTemp} / {@code #sudzEia}).
     *
     * @param tblInvNullExpr SQL-выражение нормализованного номера СФ из Tbl
     * @param tblInvExpr SQL-выражение исходного номера СФ из Tbl
     * @return фрагмент {@code OUTER APPLY (…) AS invPick}
     */
    private static String sqlInvNumVarPickApply(String tblInvNullExpr, String tblInvExpr) {
        return "OUTER APPLY ( "
                + "  SELECT 1 AS matchCnt, ranked.inKey AS pickKey "
                + "  FROM ( "
                + "    SELECT n.inKey, "
                + "           ROW_NUMBER() OVER ( "
                + "             ORDER BY "
                + "               CASE "
                + "                 WHEN LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) "
                + "                       = LTRIM(RTRIM(ISNULL(n.inNum, N''))) "
                + "                      AND LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) <> N'' "
                + "                 THEN 0 "
                + "                 WHEN n.inNumNull = " + tblInvNullExpr + " THEN 1 "
                + "                 ELSE 99 "
                + "               END, "
                + "               n.inKey "
                + "           ) AS rn "
                + "    FROM ags.invNum AS n "
                + "    WHERE n.inInv = z.iKey "
                + "      AND ( "
                + "        LTRIM(RTRIM(ISNULL(n.inNum, N''))) "
                + "            = LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) "
                + "        OR n.inNumNull = " + tblInvNullExpr + " "
                + "      ) "
                + "  ) AS ranked "
                + "  WHERE ranked.rn = 1 "
                + ") AS invPick ";
    }

    /**
     * A2.1b: добавляет {@code ags.invNum}-alias на {@code #sudzEia.iKey}, если Tbl-текст
     * ещё не представлен на этом inv (rename СФ в Excel без нового {@code ags.inv}).
     *
     * @param connection JDBC-соединение с материализованным {@code #sudzEia}
     * @param now метка времени для {@code inTimeOfEntry}
     * @return число вставленных alias
     * @throws SQLException при ошибке SQL
     */
    private int insertInvNumAliasesFromEia(Connection connection, Timestamp now) throws SQLException {
        String sql = ""
                + "INSERT INTO ags.invNum (inNum, inInv, inTimeOfEntry) "
                + "SELECT DISTINCT "
                + "       LTRIM(RTRIM(z.cidutCnInv)), "
                + "       z.iKey, "
                + "       CAST('" + now.toLocalDateTime() + "' AS datetime2) "
                + "FROM #sudzEia AS z "
                + "WHERE z.iKey IS NOT NULL "
                + "  AND z.cidutCnInv IS NOT NULL "
                + "  AND LTRIM(RTRIM(z.cidutCnInv)) <> N'' "
                + "  AND z.cidutCnInvNull <> N'NullИлиПусто' "
                + "  AND NOT EXISTS ( "
                + "    SELECT 1 FROM ags.invNum AS n "
                + "    WHERE n.inInv = z.iKey "
                + "      AND LTRIM(RTRIM(ISNULL(n.inNum, N''))) = LTRIM(RTRIM(z.cidutCnInv)) "
                + "  )";
        try (Statement statement = connection.createStatement()) {
            int n = statement.executeUpdate(sql);
            if (n > 0) {
                log.log(Level.INFO, "insertInvNumAliasesFromEia inserted={0}", n);
            }
            return n;
        }
    }

    /**
     * P4/A2: CASE-ранг совпадения Excel-номера СФ с {@code ags.invNum}
     * (exact inNum без hist-extended sibling &gt; PIT-hist extended &gt; bare inNumNull).
     * Set-based: «есть extended PIT sibling» — через {@code LEFT JOIN #hasExtPit}
     * ({@code hep.cn_key IS NULL}), не коррелированный {@code NOT EXISTS}.
     *
     * @param tblInvNullExpr SQL-выражение нормализованного номера СФ из Tbl
     * @param tblInvExpr SQL-выражение исходного номера СФ из Tbl
     * @param invNumTableAlias алиас {@code ags.invNum}
     * @param pitHistExpr выражение счётчика PIT (напр. {@code ISNULL(pit.pitHistCnt, 0)})
     * @param hasExtPitAlias алиас temp {@code #hasExtPit} (колонки {@code cn_key}, {@code cidutCnInvNull})
     * @return фрагмент {@code CASE … END}
     */
    private static String sqlInvNumRankCaseSetBased(
            String tblInvNullExpr,
            String tblInvExpr,
            String invNumTableAlias,
            String pitHistExpr,
            String hasExtPitAlias) {
        return "CASE "
                + "WHEN LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) = LTRIM(RTRIM(ISNULL("
                + invNumTableAlias + ".inNum, N''))) "
                + "AND LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) <> N'' "
                + "AND " + hasExtPitAlias + ".cn_key IS NULL THEN 0 "
                + "WHEN " + invNumTableAlias + ".inNum LIKE " + tblInvNullExpr + " + N' %' "
                + "AND " + pitHistExpr + " > 0 THEN 1 "
                + "WHEN " + invNumTableAlias + ".inNumNull = " + tblInvNullExpr
                + " AND " + pitHistExpr + " > 0 THEN 2 "
                + "WHEN LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) = LTRIM(RTRIM(ISNULL("
                + invNumTableAlias + ".inNum, N''))) "
                + "AND LTRIM(RTRIM(ISNULL(" + tblInvExpr + ", N''))) <> N'' THEN 3 "
                + "WHEN " + invNumTableAlias + ".inNumNull = " + tblInvNullExpr + " THEN 4 "
                + "WHEN " + invNumTableAlias + ".inNum LIKE " + tblInvNullExpr + " + N' %' THEN 5 "
                + "ELSE 99 END";
    }

    /**
     * P4/A2: предикат совпадения Tbl.invNum с {@code ags.invNum} (exact null или extended prefix).
     *
     * @param tblInvNullExpr SQL-выражение нормализованного номера СФ из Tbl
     * @param invNumTableAlias алиас {@code ags.invNum}
     * @return SQL-предикат
     */
    private static String sqlInvNumTblMatchWhere(String tblInvNullExpr, String invNumTableAlias) {
        return "(" + invNumTableAlias + ".inNumNull = " + tblInvNullExpr
                + " OR (" + tblInvNullExpr + " <> N'NullИлиПусто' "
                + "AND " + invNumTableAlias + ".inNum LIKE " + tblInvNullExpr + " + N' %'))";
    }

    /**
     * Префикс CTE воронки долгов до {@code existInvGrouped} (без invCand / ranking).
     * Ranking материализуется set-based в {@link #fillSudzEiaTemp}.
     *
     * @param tbl квалифицированное имя {@code CnInvDbtUplTbl}
     * @return SQL WITH … existInvGrouped AS (…)
     */
    private static String sqlDbtUplExistInvGroupedCte(String tbl) {
        return ""
                + "WITH tbl AS ( "
                + "  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN, "
                + "         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount, "
                + "         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull, "
                + "         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull "
                + "  FROM " + tbl + " AS a "
                + "  WHERE a.cidutUnloadKey = ? "
                + "), "
                + "ctptNot AS ( "
                + "  SELECT z.cidutCntrPrtNum "
                + "  FROM ( "
                + "    SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "    FROM tbl "
                + "    GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN "
                + "  ) AS z "
                + "  LEFT JOIN ags.org_id AS x "
                + "    ON z.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1 "
                + "  WHERE x.org_id_key IS NULL "
                + "), "
                + "tblCtptExist AS ( "
                + "  SELECT DISTINCT n.cidutCntrPrtNum, og.ogNm AS cidutCntrPrtName, "
                + "         n.cidutCnName, n.cidutCnDate, n.cidutCnDateNull, n.cidutCnNameNull, "
                + "         n.cidutCnInv, n.cidutCnInvNull, n.cidutAccount "
                + "  FROM tbl AS n "
                + "  LEFT JOIN ctptNot AS b ON n.cidutCntrPrtNum = b.cidutCntrPrtNum "
                + "  INNER JOIN ags.org_id AS oi "
                + "    ON n.cidutCntrPrtNum = oi.org_id_value_l AND oi.org_id_type = 1 "
                + "  LEFT JOIN ags.og AS og ON oi.org = og.ogKey "
                + "  WHERE b.cidutCntrPrtNum IS NULL "
                + "), "
                // cnCtptList / variants сужены до ключей выгрузки — иначе полный cnInv
                // даёт минуты на AccSmpl / invDbtVarEnsure (UAT 910).
                + "cnNeed AS ( "
                + "  SELECT DISTINCT cidutCnNameNull, cidutCntrPrtNum, cidutCnDateNull "
                + "  FROM tblCtptExist "
                + "), "
                + "cnCtptList AS ( "
                + "  SELECT c.cn_key, num.cnnNumNull AS cn_number, o.cn_s_org_key, "
                + "         i.org_id_value_l, "
                + "         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull "
                + "  FROM cnNeed AS need "
                + "  INNER JOIN ags.cnNum AS num ON need.cidutCnNameNull = num.cnnNumNull "
                + "  INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn "
                + "  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2 "
                + "  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s "
                + "  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl "
                + "  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key "
                + "  WHERE need.cidutCntrPrtNum = i.org_id_value_l "
                + "    AND need.cidutCnDateNull = CASE WHEN o.csoCnDate IS NULL "
                + "         THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END "
                + "), "
                + "existList AS ( "
                + "  SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, "
                + "         k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, "
                + "         l.cn_key, l.cn_s_org_key "
                + "  FROM tblCtptExist AS k "
                + "  INNER JOIN cnCtptList AS l "
                + "    ON k.cidutCnNameNull = l.cn_number "
                + "   AND k.cidutCnDateNull = l.csoCnDateNull "
                + "   AND k.cidutCntrPrtNum = l.org_id_value_l "
                + "  GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, "
                + "           k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, "
                + "           l.cn_key, l.cn_s_org_key "
                + "), "
                + "existInvGrouped AS ( "
                + "  SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, "
                + "         h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull, "
                + "         t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key "
                + "  FROM existList AS h "
                + "  LEFT JOIN tbl AS t "
                + "    ON h.cidutCntrPrtNum = t.cidutCntrPrtNum "
                + "   AND h.cidutCnNameNull = t.cidutCnNameNull "
                + "   AND h.cidutCnDateNull = t.cidutCnDateNull "
                + "  GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, "
                + "           h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull, "
                + "           t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key "
                + ") ";
    }

    /**
     * AccSmpl поверх {@code #sudzEia} (без повторного инлайна existInvAll).
     *
     * @param tbl квалифицированное имя Tbl
     * @return SQL WITH … accSmplNot AS (…)
     */
    private static String sqlDbtUplAccSmplNotFromEia(String tbl) {
        return ""
                + "WITH accY AS ( "
                + "  SELECT t.cidutCntrPrtNum, "
                + "         CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(t.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END AS cidutCnNameNull, "
                + "         CASE WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END AS cidutCnInvNull, "
                + "         acc.account_num, acc.account_key "
                + "  FROM " + tbl + " AS t "
                + "  INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key "
                + "  WHERE t.cidutUnloadKey = ? "
                + "), "
                + "accSmplAll AS ( "
                + "  SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, "
                + "         z.cidutCnNameNull, z.cidutCnDate, z.cidutCnInv, "
                + "         z.cn_key, z.iKey, z.ciKey, y.account_num, y.account_key, "
                + "         matched.ciasKey "
                + "  FROM #sudzEia AS z "
                + "  LEFT JOIN accY AS y "
                + "    ON z.cidutCnInvNull = y.cidutCnInvNull "
                + "   AND z.cidutCnDateNull = y.cidutCnDateNull "
                + "   AND z.cidutCnNameNull = y.cidutCnNameNull "
                + "   AND z.cidutCntrPrtNum = y.cidutCntrPrtNum "
                + "  OUTER APPLY ( "
                + "    SELECT TOP 1 s.ciasKey "
                + "    FROM ags.cnInvAccntSmpl AS s "
                + "    INNER JOIN ags.cn_s_org_smpl AS o ON s.ciasCn_s_org_smpl = o.csosKey "
                + "    INNER JOIN ags.org_id AS i ON o.csosOrgId = i.org_id_key "
                + "    WHERE s.ciasCnInv = z.ciKey "
                + "      AND s.ciasAccnt = y.account_key "
                + "      AND i.org_id_value_l = z.cidutCntrPrtNum "
                + "  ) AS matched "
                + "  WHERE z.ciKey IS NOT NULL "
                + "), "
                + "accSmplNot AS ( "
                + "  SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull, "
                + "         cidutCnDate, cidutCnInv, cn_key, iKey, ciKey, "
                + "         account_num, account_key "
                + "  FROM accSmplAll "
                + "  WHERE ciasKey IS NULL AND account_key IS NOT NULL "
                + ") ";
    }

    /**
     * CTE шага {@code invDbtVarEnsure} поверх материализованного {@code #sudzEia}.
     * Не ссылается на existInvAll повторно — иначе SQL Server инлайнит CTE в nested loop на минуты.
     * cnNum/invNum: выбор по тексту Excel (сегм. 22f), не по единственности записи в ags на договор/СФ.
     *
     * @param tbl квалифицированное имя Tbl
     * @param invDbtVar квалифицированное имя {@code invDbtVar}
     * @param invDbt квалифицированное имя {@code invDbt}
     * @param dbtValue квалифицированное имя {@code DbtValue}
     * @return SQL WITH … ctx AS (…)
     */
    private static String sqlDbtUplInvDbtVarEnsureCte(
            String tbl,
            String invDbtVar,
            String invDbt,
            String dbtValue
    ) {
        return ""
                + "WITH accY AS ( "
                + "  SELECT t.cidutCntrPrtNum, "
                + "         CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(t.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END AS cidutCnNameNull, "
                + "         CASE WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END AS cidutCnInvNull, "
                + "         acc.account_num, acc.account_key "
                + "  FROM " + tbl + " AS t "
                + "  INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key "
                + "  WHERE t.cidutUnloadKey = ? "
                + "), "
                + "ctxBase AS ( "
                + "  SELECT DISTINCT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, "
                + "         z.cidutCnDate, z.cidutCnInv, z.cidutCnInvNull, z.iKey, "
                + "         z.cn_s_org_key, y.account_key, y.account_num, "
                + "         CASE WHEN cnnPick.matchCnt = 1 THEN cnnPick.pickKey END AS cnnKey, "
                + "         CASE WHEN invPick.matchCnt = 1 THEN invPick.pickKey END AS invNumKey "
                + "  FROM #sudzEia AS z "
                + "  INNER JOIN accY AS y "
                + "    ON z.cidutCnInvNull = y.cidutCnInvNull "
                + "   AND z.cidutCnDateNull = y.cidutCnDateNull "
                + "   AND z.cidutCnNameNull = y.cidutCnNameNull "
                + "   AND z.cidutCntrPrtNum = y.cidutCntrPrtNum "
                + "  OUTER APPLY ( "
                + "    SELECT COUNT(DISTINCT n.cnnKey) AS matchCnt, MIN(n.cnnKey) AS pickKey "
                + "    FROM ags.cnNum AS n "
                + "    WHERE n.cnnCn = z.cn_key AND n.cnnType = 1 "
                + "      AND n.cnnNumNull = z.cidutCnNameNull "
                + "  ) AS cnnPick "
                + sqlInvNumVarPickApply("z.cidutCnInvNull", "z.cidutCnInv")
                + "  WHERE z.iKey IS NOT NULL "
                + "    AND z.cn_s_org_key IS NOT NULL "
                + "    AND y.account_key IS NOT NULL "
                + "), "
                + "ctx AS ( "
                + "  SELECT b.cidutCntrPrtNum, b.cidutCntrPrtName, b.cidutCnName, "
                + "         b.cidutCnDate, b.cidutCnInv, b.iKey, b.cn_s_org_key, "
                + "         b.account_key, b.account_num, b.cnnKey, b.invNumKey, "
                + "         v.idvvKey "
                + "  FROM ctxBase AS b "
                + "  LEFT JOIN " + invDbtVar + " AS v "
                + "    ON v.idvvCnNum = b.cnnKey "
                + "   AND v.idvvInvNum = b.invNumKey "
                + "   AND v.idvvAccnt = b.account_key "
                + "   AND v.idvvCn_s_org = b.cn_s_org_key "
                + ") ";
    }

    /**
     * CTE истории multi (сегм. 13 OR): {@code sudz.invDbt} &gt;1 слот; named {@code cnInvAccnt};
     * в какой-то выгрузке &gt;1 {@code ags.cn_inv_dbt} на {@code iKey}.
     * Lifetime «всего строк cn_inv_dbt >1» не используется (это обычные
     * повторные появления одного долга по кварталам).
     *
     * @param invDbt квалифицированное имя {@code invDbt}
     * @return фрагмент {@code , histInvDbtMulti AS (...), histNamedAccMulti AS (...), histCidMulti AS (...)}
     */
    private static String sqlInvDbtHistMultiCtes(String invDbt) {
        return ""
                + ", "
                + "histInvDbtMulti AS ( "
                + "  SELECT idInv AS iKey FROM " + invDbt + " "
                + "  GROUP BY idInv HAVING COUNT(*) > 1 "
                + "), "
                + "histNamedAccMulti AS ( "
                + "  SELECT ci.ciInv AS iKey "
                + "  FROM ags.cnInvAccnt AS a "
                + "  INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey "
                + "  INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey "
                + "  WHERE a.ciaName IS NOT NULL "
                + "  GROUP BY ci.ciInv "
                + "  HAVING COUNT(*) > 1 "
                + "), "
                + "histCidMulti AS ( "
                + "  SELECT DISTINCT y.iKey "
                + "  FROM ( "
                + "    SELECT ci.ciInv AS iKey "
                + "    FROM ags.cn_inv_dbt AS d "
                + "    INNER JOIN ags.cnInvAccnt AS a ON a.ciaKey = d.cidCnInvAccntCtpt "
                + "    INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey "
                + "    INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey "
                + "    GROUP BY ci.ciInv, d.cn_inv_dbt_upl "
                + "    HAVING COUNT(*) > 1 "
                + "  ) AS y "
                + ") ";
    }

    /**
     * Предикат A1: не вставлять {@code DbtValue}, если sibling-слот того же {@code iKey}
     * уже имеет Value на этой выгрузке (при {@code tblIKey.rowCnt=1}) или с той же суммой (±0.01).
     * Ожидает CTE {@code tblIKey(iKey, rowCnt)} в том же запросе.
     *
     * @param invDbt квалифицированное имя {@code invDbt}
     * @param dbtValue квалифицированное имя {@code DbtValue}
     * @param upl ключ выгрузки
     * @param slotCol выражение PK слота (напр. {@code d.idKey})
     * @param iKeyCol выражение {@code iKey} (напр. {@code c.iKey})
     * @param debtExpr выражение суммы Tbl как {@code decimal(19,4)}
     * @return SQL-фрагмент {@code NOT EXISTS (…)}
     */
    private static String sqlNoSiblingValueAtUpl(
            String invDbt,
            String dbtValue,
            int upl,
            String slotCol,
            String iKeyCol,
            String debtExpr
    ) {
        return sqlNoSiblingValueAtUpl(invDbt, dbtValue, upl, slotCol, iKeyCol, debtExpr, "tblIKey");
    }

    /**
     * @param tblIKeySource CTE {@code tblIKey} или temp {@code #tblIKey}
     */
    private static String sqlNoSiblingValueAtUpl(
            String invDbt,
            String dbtValue,
            int upl,
            String slotCol,
            String iKeyCol,
            String debtExpr,
            String tblIKeySource
    ) {
        return "NOT EXISTS ( "
                + "  SELECT 1 FROM " + invDbt + " AS sib "
                + "  INNER JOIN " + dbtValue + " AS dvSib "
                + "    ON dvSib.dvInvDbt = sib.idKey AND dvSib.dvUpl = " + upl + " "
                + "  WHERE sib.idInv = " + iKeyCol + " AND sib.idKey <> " + slotCol + " "
                + "    AND ( "
                + "      COALESCE((SELECT ti.rowCnt FROM " + tblIKeySource + " AS ti "
                + "                WHERE ti.iKey = " + iKeyCol + "), 1) = 1 "
                + "      OR ABS(CAST(dvSib.dvTtl AS decimal(19,4)) - " + debtExpr + ") "
                + "          <= CAST(0.01 AS decimal(19,4)) "
                + "    ) "
                + ") ";
    }

    /**
     * Префикс CTE {@code ctx} из материализованной {@code #invDbtCtx} (без повторного ctxBase).
     */
    private static String sqlInvDbtCtxFromTempCte() {
        return ""
                + "WITH ctx AS ( "
                + "  SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnDate, cidutCnInv, "
                + "         iKey, cn_s_org_key, account_key, account_num, cnnKey, invNumKey, idvvKey "
                + "  FROM #invDbtCtx "
                + ") ";
    }

    /**
     * Сброс temp-наборов invDbtLoad на соединении.
     */
    private static void dropInvDbtLoadTemps(Connection connection) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(
                    "IF OBJECT_ID('tempdb..#invDbtCtx') IS NOT NULL DROP TABLE #invDbtCtx; "
                            + "IF OBJECT_ID('tempdb..#tblIKey') IS NOT NULL DROP TABLE #tblIKey; "
                            + "IF OBJECT_ID('tempdb..#calmOne') IS NOT NULL DROP TABLE #calmOne; "
                            + "IF OBJECT_ID('tempdb..#f1One') IS NOT NULL DROP TABLE #f1One; "
                            + "IF OBJECT_ID('tempdb..#rowMatch') IS NOT NULL DROP TABLE #rowMatch; "
                            + "IF OBJECT_ID('tempdb..#invDbtQDetail') IS NOT NULL DROP TABLE #invDbtQDetail");
        }
    }

    /**
     * Материализует {@code ctx} в {@code #invDbtCtx} (один проход accY/ctxBase).
     */
    private void materializeInvDbtCtxTemp(
            Connection connection,
            int unloadKey,
            String tbl,
            String invDbtVar,
            String invDbt,
            String dbtValue
    ) throws SQLException {
        String sql = bindUnloadKeyLiterals(
                sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, invDbt, dbtValue)
                        + "SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnDate, cidutCnInv, "
                        + "       iKey, cn_s_org_key, account_key, account_num, cnnKey, invNumKey, idvvKey "
                        + "INTO #invDbtCtx FROM ctx OPTION (RECOMPILE)",
                unloadKey);
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(sql);
        }
    }

    /**
     * Подтягивает {@code idvvKey} в {@code #invDbtCtx} после {@code invDbtVarEnsure}
     * (материализация ctx могла быть до INSERT в {@code invDbtVar}).
     */
    private void refreshInvDbtCtxIdvvKeys(Connection connection, String invDbtVar) throws SQLException {
        String sql = ""
                + "UPDATE c SET c.idvvKey = v.idvvKey "
                + "FROM #invDbtCtx AS c "
                + "INNER JOIN " + invDbtVar + " AS v "
                + "  ON v.idvvCnNum = c.cnnKey AND v.idvvInvNum = c.invNumKey "
                + " AND v.idvvAccnt = c.account_key AND v.idvvCn_s_org = c.cn_s_org_key "
                + "WHERE c.idvvKey IS NULL AND c.cnnKey IS NOT NULL AND c.invNumKey IS NOT NULL";
        try (Statement statement = connection.createStatement()) {
            int updated = statement.executeUpdate(sql);
            if (updated > 0) {
                log.log(Level.INFO, "refreshInvDbtCtxIdvvKeys updated={0}", updated);
            }
        }
    }

    /**
     * Материализует {@code #tblIKey}, {@code #calmOne}, {@code #f1One} для apply invDbtLoad.
     */
    private void materializeInvDbtLoadWorkset(
            Connection connection,
            int unloadKey,
            String tbl,
            String invDbt,
            String invDbtDbt,
            String linkGroup,
            String linkMember,
            String dbtValue,
            String queue
    ) throws SQLException {
        String uplLit = Integer.toString(unloadKey);
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(
                    "SELECT e.iKey, COUNT(DISTINCT a.cidutKey) AS rowCnt "
                            + "INTO #tblIKey "
                            + "FROM " + tbl + " AS a "
                            + "INNER JOIN #sudzEia AS e "
                            + "  ON e.cidutCntrPrtNum = a.cidutCntrPrtNum "
                            + " AND e.cidutCnNameNull = CASE "
                            + "       WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                            + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END "
                            + " AND e.cidutCnDateNull = CASE "
                            + "       WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                            + "       ELSE CAST(a.cidutCnDate AS date) END "
                            + " AND e.cidutCnInvNull = CASE "
                            + "       WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                            + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END "
                            + "WHERE a.cidutUnloadKey = " + uplLit + " AND e.iKey IS NOT NULL "
                            + "GROUP BY e.iKey OPTION (RECOMPILE)");
        }
        String calmSql = sqlInvDbtCtxFromTempCte()
                + ", resolvedUnique AS ( "
                + "  SELECT * FROM ctx "
                + "  WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NOT NULL "
                + "), queuedIKeys AS ( "
                + "  SELECT DISTINCT ciudIKey AS iKey FROM " + queue
                + "  WHERE ciudUnloadKey = " + uplLit + " AND ciudIKey IS NOT NULL "
                + ") "
                + sqlInvDbtHistMultiCtes(invDbt)
                + ", currentMulti AS ( "
                + "  SELECT iKey FROM #tblIKey WHERE rowCnt > 1 "
                + "), multiCtx AS ( "
                + "  SELECT iKey FROM resolvedUnique "
                + "  GROUP BY iKey "
                + "  HAVING COUNT(DISTINCT CONCAT( "
                + "    CAST(cnnKey AS varchar(20)), N'|', "
                + "    CAST(invNumKey AS varchar(20)), N'|', "
                + "    CAST(account_key AS varchar(20)), N'|', "
                + "    CAST(cn_s_org_key AS varchar(20)))) > 1 "
                + "), calm AS ( "
                + "  SELECT r.iKey, r.idvvKey "
                + "  FROM resolvedUnique AS r "
                + "  WHERE NOT EXISTS (SELECT 1 FROM queuedIKeys q WHERE q.iKey = r.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM histInvDbtMulti h WHERE h.iKey = r.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM histNamedAccMulti h WHERE h.iKey = r.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM histCidMulti h WHERE h.iKey = r.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM currentMulti m WHERE m.iKey = r.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM multiCtx m WHERE m.iKey = r.iKey) "
                + "), calmOne AS ( "
                + "  SELECT iKey, MIN(idvvKey) AS idvvKey "
                + "  FROM calm "
                + "  GROUP BY iKey "
                + "  HAVING COUNT(DISTINCT idvvKey) = 1 "
                + ") "
                + "SELECT iKey, idvvKey INTO #calmOne FROM calmOne OPTION (RECOMPILE)";
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(calmSql);
        }
        String f1Sql = sqlInvDbtCtxFromTempCte()
                + ", currentMulti AS ( "
                + "  SELECT iKey FROM #tblIKey WHERE rowCnt > 1 "
                + "), multiCtx AS ( "
                + "  SELECT iKey FROM ctx "
                + "  WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NOT NULL "
                + "  GROUP BY iKey "
                + "  HAVING COUNT(DISTINCT CONCAT( "
                + "    CAST(cnnKey AS varchar(20)), N'|', "
                + "    CAST(invNumKey AS varchar(20)), N'|', "
                + "    CAST(account_key AS varchar(20)), N'|', "
                + "    CAST(cn_s_org_key AS varchar(20)))) > 1 "
                + ") "
                + sqlInvDbtF1MatchCtes(tbl, invDbt, invDbtDbt, linkGroup, linkMember, dbtValue,
                "a.cidutUnloadKey = " + uplLit)
                + ", resolvedUnique AS ( "
                + "  SELECT * FROM ctx "
                + "  WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NOT NULL "
                + "), f1One AS ( "
                + "  SELECT f.iKey, f.idInvDbt, MIN(r.idvvKey) AS idvvKey "
                + "  FROM f1Unique AS f "
                + "  INNER JOIN resolvedUnique AS r ON r.iKey = f.iKey "
                + "  WHERE NOT EXISTS (SELECT 1 FROM currentMulti m WHERE m.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM multiCtx m WHERE m.iKey = f.iKey) "
                + "  GROUP BY f.iKey, f.idInvDbt "
                + "  HAVING COUNT(DISTINCT r.idvvKey) = 1 "
                + ") "
                + "SELECT iKey, idInvDbt, idvvKey INTO #f1One FROM f1One OPTION (RECOMPILE)";
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(f1Sql);
        }
    }

    /**
     * M3 Calm F1: Excel-сумма однозначно совпадает с историей {@code DbtValue}
     * ровно одного слота {@code invDbt} на {@code iKey} (ε=0.01).
     * Ожидает {@code #sudzEia}. Предикат выгрузки — литерал или {@code ?}.
     *
     * @param tbl квалифицированное имя staging Tbl
     * @param invDbt квалифицированное имя {@code invDbt}
     * @param invDbtDbt квалифицированное имя {@code invDbtDbt}
     * @param linkGroup квалифицированное имя {@code DbtSlotLinkGroup}
     * @param linkMember квалифицированное имя {@code DbtSlotLinkMember}
     * @param dbtValue квалифицированное имя {@code DbtValue}
     * @param unloadPred фрагмент {@code a.cidutUnloadKey = …}
     * @return CTE {@code f1Excel}, {@code f1Cand}, {@code f1Unique}
     */
    private static String sqlInvDbtF1MatchCtes(
            String tbl,
            String invDbt,
            String invDbtDbt,
            String linkGroup,
            String linkMember,
            String dbtValue,
            String unloadPred
    ) {
        return ""
                + ", "
                + "f1Excel AS ( "
                + "  SELECT e.iKey, "
                + "         MIN(CAST(a.cidutDebt AS decimal(19,4))) AS debt, "
                + "         COUNT(DISTINCT a.cidutKey) AS rowCnt, "
                + "         COUNT(DISTINCT CAST(a.cidutDebt AS decimal(19,4))) AS debtVariants "
                + "  FROM " + tbl + " AS a "
                + "  INNER JOIN #sudzEia AS e "
                + "    ON e.cidutCntrPrtNum = a.cidutCntrPrtNum "
                + "   AND e.cidutCnNameNull = CASE "
                + "         WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "         THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END "
                + "   AND e.cidutCnDateNull = CASE "
                + "         WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "         ELSE CAST(a.cidutCnDate AS date) END "
                + "   AND e.cidutCnInvNull = CASE "
                + "         WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "         THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END "
                + "  WHERE " + unloadPred + " AND e.iKey IS NOT NULL "
                + "  GROUP BY e.iKey "
                + "), "
                + "f1Cand AS ( "
                + "  SELECT x.iKey, d.idKey AS idInvDbt "
                + "  FROM f1Excel AS x "
                + "  INNER JOIN " + invDbt + " AS d ON d.idInv = x.iKey "
                + "  WHERE x.rowCnt = 1 AND x.debtVariants = 1 "
                + "    AND EXISTS ( "
                + "      SELECT 1 FROM " + dbtValue + " AS dv "
                + "      WHERE dv.dvInvDbt = d.idKey "
                + "        AND ABS(CAST(dv.dvTtl AS decimal(19,4)) - x.debt) "
                + "            <= CAST(0.01 AS decimal(19,4)) "
                + "    ) "
                + "), "
                + "f1CandRanked AS ( "
                + "  SELECT c.iKey, c.idInvDbt, "
                + "         ROW_NUMBER() OVER ( "
                + "           PARTITION BY c.iKey "
                + "           ORDER BY "
                + "             (SELECT COUNT(DISTINCT dvH.dvUpl) FROM " + dbtValue + " AS dvH "
                + "              WHERE dvH.dvInvDbt = c.idInvDbt AND dvH.dvUpl IN (801, 802, 803)) DESC, "
                + "             CASE WHEN EXISTS ( "
                + "               SELECT 1 FROM " + invDbtDbt + " AS iddC "
                + "               INNER JOIN " + linkGroup + " AS g "
                + "                 ON g.canonicalDbtKey = iddC.iddDbt AND g.dslgStatus = N'active' "
                + "               INNER JOIN " + linkMember + " AS m ON m.lid = g.lid "
                + "               INNER JOIN " + invDbt + " AS sl "
                + "                 ON sl.idKey = c.idInvDbt AND sl.idInv = m.iKey AND sl.idNum = m.idNum "
                + "               WHERE iddC.iddInvDbt = c.idInvDbt "
                + "             ) THEN 0 ELSE 1 END, "
                + "             c.idInvDbt ASC "
                + "         ) AS rn "
                + "  FROM f1Cand AS c "
                + "), "
                + "f1Unique AS ( "
                + "  SELECT iKey, idInvDbt FROM f1CandRanked WHERE rn = 1 "
                + ") ";
    }

    /**
     * Материализует {@code existInvAll} в {@code #sudzEia} set-based:
     * {@code #sudzEig} → {@code #pitByInv} → {@code #hasExtPit} → ranking → {@code #sudzEia}.
     * Убирает коррелированный {@code NOT EXISTS}+PIT на каждую строку invCand (~150 с → секунды).
     * Только {@link Statement}: {@code PreparedStatement}/{@code sp_prepexec} не видит
     * локальный temp на том же connection (Invalid object name #sudzEia).
     *
     * @param connection открытое JDBC-соединение
     * @param unloadKey {@code cidutUnloadKey} (уже проверен &gt; 0)
     * @throws SQLException при ошибке SQL
     */
    private void fillSudzEiaTemp(Connection connection, int unloadKey) throws SQLException {
        String tbl = q("CnInvDbtUplTbl");
        String invDbt = q("invDbt");
        String dbtValue = q("DbtValue");
        long t0 = System.nanoTime();
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("IF OBJECT_ID('tempdb..#sudzEia') IS NOT NULL DROP TABLE #sudzEia");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#sudzEig') IS NOT NULL DROP TABLE #sudzEig");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#pitByInv') IS NOT NULL DROP TABLE #pitByInv");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#hasExtPit') IS NOT NULL DROP TABLE #hasExtPit");

            long s0 = System.nanoTime();
            String eigSql = sqlDbtUplExistInvGroupedCte(tbl)
                    .replace("a.cidutUnloadKey = ?", "a.cidutUnloadKey = " + unloadKey)
                    + "SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull, "
                    + "       cidutCnDate, cidutCnDateNull, cidutCnInv, cidutCnInvNull, "
                    + "       cn_key, cn_s_org_key "
                    + "INTO #sudzEig "
                    + "FROM existInvGrouped "
                    + "OPTION (RECOMPILE)";
            statement.executeUpdate(eigSql);
            statement.executeUpdate(
                    "CREATE NONCLUSTERED INDEX IX_sudzEig_cn ON #sudzEig (cn_key)");
            statement.executeUpdate(
                    "CREATE NONCLUSTERED INDEX IX_sudzEig_excel ON #sudzEig "
                            + "(cn_key, cidutCnInvNull)");
            long eigMs = (System.nanoTime() - s0) / 1_000_000L;

            s0 = System.nanoTime();
            // PIT-история по iKey только для СФ на matched договорах выгрузки.
            statement.executeUpdate(
                    "SELECT id.idInv AS iKey, COUNT(DISTINCT dv.dvUpl) AS pitHistCnt "
                            + "INTO #pitByInv "
                            + "FROM (SELECT DISTINCT cn_key FROM #sudzEig) AS e "
                            + "INNER JOIN ags.cnInv AS ci ON ci.ciCn = e.cn_key "
                            + "INNER JOIN " + invDbt + " AS id ON id.idInv = ci.ciInv "
                            + "INNER JOIN " + dbtValue + " AS dv ON dv.dvInvDbt = id.idKey "
                            + "WHERE dv.dvUpl IN (801, 802, 803) "
                            + "GROUP BY id.idInv "
                            + "OPTION (RECOMPILE)");
            statement.executeUpdate(
                    "CREATE UNIQUE CLUSTERED INDEX IX_pitByInv_iKey ON #pitByInv (iKey)");
            long pitMs = (System.nanoTime() - s0) / 1_000_000L;

            s0 = System.nanoTime();
            // Пары (cn, excelNull), у которых есть extended invNum с PIT — для ветки rank=0.
            statement.executeUpdate(
                    "SELECT DISTINCT f.cn_key, f.cidutCnInvNull "
                            + "INTO #hasExtPit "
                            + "FROM #sudzEig AS f "
                            + "WHERE EXISTS ( "
                            + "  SELECT 1 "
                            + "  FROM ags.cnInv AS ciX "
                            + "  INNER JOIN ags.invNum AS nx ON nx.inInv = ciX.ciInv "
                            + "  INNER JOIN #pitByInv AS p ON p.iKey = ciX.ciInv "
                            + "  WHERE ciX.ciCn = f.cn_key "
                            + "    AND nx.inNum LIKE f.cidutCnInvNull + N' %' "
                            + "    AND p.pitHistCnt > 0 "
                            + ") "
                            + "OPTION (RECOMPILE)");
            statement.executeUpdate(
                    "CREATE UNIQUE CLUSTERED INDEX IX_hasExtPit ON #hasExtPit "
                            + "(cn_key, cidutCnInvNull)");
            long hepMs = (System.nanoTime() - s0) / 1_000_000L;

            s0 = System.nanoTime();
            String rankCase = sqlInvNumRankCaseSetBased(
                    "f.cidutCnInvNull", "f.cidutCnInv", "n",
                    "ISNULL(pit.pitHistCnt, 0)", "hep");
            String eiaSql = ""
                    + "WITH invCand AS ( "
                    + "  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, "
                    + "         f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull, "
                    + "         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, "
                    + "         ci.ciKey, inv.iKey, n.inKey AS invNumKey, "
                    + "         " + rankCase + " AS invMatchRank, "
                    + "         ISNULL(pit.pitHistCnt, 0) AS pitHistCnt "
                    + "  FROM #sudzEig AS f "
                    + "  INNER JOIN ags.cnInv AS ci ON ci.ciCn = f.cn_key "
                    + "  INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv "
                    + "  INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey "
                    + "  LEFT JOIN #pitByInv AS pit ON pit.iKey = inv.iKey "
                    + "  LEFT JOIN #hasExtPit AS hep "
                    + "    ON hep.cn_key = f.cn_key AND hep.cidutCnInvNull = f.cidutCnInvNull "
                    + "  WHERE " + sqlInvNumTblMatchWhere("f.cidutCnInvNull", "n") + " "
                    + "), "
                    + "invCiRanked AS ( "
                    + "  SELECT c.*, ROW_NUMBER() OVER ( "
                    + "    PARTITION BY c.cidutCntrPrtNum, c.cidutCnNameNull, c.cidutCnDateNull, "
                    + "                  c.cidutCnInvNull, c.cn_key "
                    + "    ORDER BY c.invMatchRank, c.pitHistCnt DESC, c.invNumKey ASC "
                    + "  ) AS rn "
                    + "  FROM invCand AS c "
                    + "  WHERE c.invMatchRank < 99 "
                    + "), "
                    + "existInvAll AS ( "
                    + "  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, "
                    + "         f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull, "
                    + "         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, "
                    + "         r.iKey, r.ciKey "
                    + "  FROM #sudzEig AS f "
                    + "  LEFT JOIN invCiRanked AS r "
                    + "    ON r.cidutCntrPrtNum = f.cidutCntrPrtNum "
                    + "   AND r.cidutCnNameNull = f.cidutCnNameNull "
                    + "   AND r.cidutCnDateNull = f.cidutCnDateNull "
                    + "   AND r.cidutCnInvNull = f.cidutCnInvNull "
                    + "   AND r.cn_key = f.cn_key "
                    + "   AND r.rn = 1 "
                    + ") "
                    + "SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull, "
                    + "       cidutCnDate, cidutCnDateNull, cidutCnInv, cidutCnInvNull, "
                    + "       cn_key, cn_s_org_key, iKey, ciKey "
                    + "INTO #sudzEia "
                    + "FROM existInvAll "
                    + "OPTION (RECOMPILE)";
            int n = statement.executeUpdate(eiaSql);
            statement.executeUpdate(
                    "CREATE CLUSTERED INDEX IX_sudzEia_ciKey ON #sudzEia (ciKey)");
            statement.executeUpdate(
                    "CREATE NONCLUSTERED INDEX IX_sudzEia_excel ON #sudzEia "
                            + "(cidutCntrPrtNum, cidutCnNameNull, cidutCnDateNull, cidutCnInvNull)");
            long eiaMs = (System.nanoTime() - s0) / 1_000_000L;

            statement.executeUpdate("IF OBJECT_ID('tempdb..#sudzEig') IS NOT NULL DROP TABLE #sudzEig");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#pitByInv') IS NOT NULL DROP TABLE #pitByInv");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#hasExtPit') IS NOT NULL DROP TABLE #hasExtPit");

            long totalMs = (System.nanoTime() - t0) / 1_000_000L;
            log.log(Level.INFO,
                    "fillSudzEiaTemp unloadKey={0} rows={1} eigMs={2} pitMs={3} hepMs={4} eiaMs={5} totalMs={6}",
                    new Object[]{unloadKey, n, eigMs, pitMs, hepMs, eiaMs, totalMs});
        }
    }

    /**
     * Подставляет литерал {@code unloadKey} вместо {@code ?} в SQL поверх {@code #sudzEia}.
     * Нужен {@link Statement}, не PreparedStatement (см. {@link #fillSudzEiaTemp}).
     *
     * @param sql шаблон с {@code ?} для unloadKey
     * @param unloadKey ключ выгрузки
     * @return SQL с литералом
     */
    private static String bindUnloadKeyLiterals(String sql, int unloadKey) {
        return sql.replace("?", Integer.toString(unloadKey));
    }

    @Override
    public List<SudzDbtUplAccSmplNotRow> findDbtUplCnCtptInvExistAccSmplNot(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            long t0 = System.nanoTime();
            fillSudzEiaTemp(connection, unloadKey);
            long fillMs = (System.nanoTime() - t0) / 1_000_000L;
            long q0 = System.nanoTime();
            List<SudzDbtUplAccSmplNotRow> rows = readAccSmplNotRows(connection, unloadKey);
            long queryMs = (System.nanoTime() - q0) / 1_000_000L;
            log.log(Level.INFO,
                    "findDbtUplCnCtptInvExistAccSmplNot unloadKey={0} rows={1} fillMs={2} queryMs={3}",
                    new Object[]{unloadKey, rows.size(), fillMs, queryMs});
            return rows;
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать AccSmplNot unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplAccSmplNotApplyResult applyDbtUplCnCtptInvExistAccSmplNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                fillSudzEiaTemp(connection, unloadKey);
                SudzDbtUplAccSmplNotApplyResult result = applyAccSmplOnConnection(connection, unloadKey, now);
                connection.commit();
                log.log(Level.INFO,
                        "applyDbtUplCnCtptInvExistAccSmplNotLoad unloadKey={0} inserted={1}",
                        new Object[]{unloadKey, result.insertedCount()});
                return result;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply AccSmplNotLoad unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplAccSmplNotLoadResult findAndApplyDbtUplCnCtptInvExistAccSmplNotLoad(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                long t0 = System.nanoTime();
                fillSudzEiaTemp(connection, unloadKey);
                long fillMs = (System.nanoTime() - t0) / 1_000_000L;
                long q0 = System.nanoTime();
                List<SudzDbtUplAccSmplNotRow> rows = readAccSmplNotRows(connection, unloadKey);
                long queryMs = (System.nanoTime() - q0) / 1_000_000L;
                SudzDbtUplAccSmplNotApplyResult apply = applyAccSmplOnConnection(connection, unloadKey, now);
                connection.commit();
                log.log(Level.INFO,
                        "findAndApply AccSmplNotLoad unloadKey={0} rows={1} inserted={2} "
                                + "fillMs={3} queryMs={4}",
                        new Object[]{unloadKey, rows.size(), apply.insertedCount(), fillMs, queryMs});
                return new SudzDbtUplAccSmplNotLoadResult(rows, apply);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить findAndApply AccSmplNotLoad unloadKey=" + unloadKey, exception);
        }
    }

    private List<SudzDbtUplAccSmplNotRow> readAccSmplNotRows(Connection connection, int unloadKey)
            throws SQLException {
        String tbl = q("CnInvDbtUplTbl");
        String bound = sqlDbtUplAccSmplNotFromEia(tbl)
                .replace("t.cidutUnloadKey = ?", "t.cidutUnloadKey = " + unloadKey)
                + "SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnDate, "
                + "       h.cn_key, h.cidutCnInv, h.iKey, h.ciKey, "
                + "       h.account_num, h.account_key "
                + "FROM accSmplNot AS h "
                + "ORDER BY h.cn_key, h.cidutCnInv, h.account_key, h.ciKey "
                + "OPTION (RECOMPILE)";
        List<SudzDbtUplAccSmplNotRow> rows = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(bound)) {
            while (rs.next()) {
                Date cnDateSql = rs.getDate("cidutCnDate");
                LocalDate cnDate = cnDateSql == null ? null : cnDateSql.toLocalDate();
                Integer cntrPrtNum = (Integer) rs.getObject("cidutCntrPrtNum");
                rows.add(new SudzDbtUplAccSmplNotRow(
                        cntrPrtNum,
                        rs.getNString("cidutCntrPrtName"),
                        rs.getNString("cidutCnName"),
                        cnDate,
                        rs.getInt("cn_key"),
                        rs.getNString("cidutCnInv"),
                        rs.getInt("iKey"),
                        rs.getInt("ciKey"),
                        rs.getInt("account_num"),
                        rs.getInt("account_key")
                ));
            }
        }
        return List.copyOf(rows);
    }

    private SudzDbtUplAccSmplNotApplyResult applyAccSmplOnConnection(
            Connection connection,
            int unloadKey,
            Timestamp now
    ) throws SQLException {
        String tbl = q("CnInvDbtUplTbl");
        String bound = sqlDbtUplAccSmplNotFromEia(tbl)
                .replace("t.cidutUnloadKey = ?", "t.cidutUnloadKey = " + unloadKey)
                + "INSERT INTO ags.cnInvAccntSmpl "
                + "  (ciasCnInv, ciasAccnt, ciasCn_s_org_smpl, ciasTimeOfEntry) "
                + "SELECT a.ciKey, a.account_key, z.csosKey, "
                + "       CAST('" + now.toLocalDateTime() + "' AS datetime2) "
                + "FROM accSmplNot AS a "
                + "INNER JOIN ( "
                + "  SELECT css.csosKey, cn.cnnNumNull, i.org_id_value_l "
                + "  FROM ags.cn_s_org_smpl AS css "
                + "  INNER JOIN ags.cn_s AS cs ON css.csosCn_s = cs.cn_s_key "
                + "  INNER JOIN ags.cn AS c ON cs.cn_key = c.cn_key "
                + "  INNER JOIN ags.cnNum AS cn ON c.cn_key = cn.cnnCn "
                + "  INNER JOIN ags.org_id AS i ON css.csosOrgId = i.org_id_key "
                + "  WHERE i.org_id_value_l IS NOT NULL "
                + "    AND i.org_id_type = 1 "
                + "    AND cs.cn_s_type = 2 "
                + ") AS z ON a.cidutCnNameNull = z.cnnNumNull "
                + "       AND a.cidutCntrPrtNum = z.org_id_value_l "
                + "WHERE NOT EXISTS ( "
                + "  SELECT 1 FROM ags.cnInvAccntSmpl AS f "
                + "  WHERE f.ciasCnInv = a.ciKey "
                + "    AND f.ciasAccnt = a.account_key "
                + "    AND f.ciasCn_s_org_smpl = z.csosKey "
                + ") "
                + "GROUP BY a.ciKey, a.account_key, z.csosKey";
        try (Statement statement = connection.createStatement()) {
            int inserted = statement.executeUpdate(bound);
            log.log(Level.INFO,
                    "applyAccSmplOnConnection unloadKey={0} inserted={1}",
                    new Object[]{unloadKey, inserted});
            return new SudzDbtUplAccSmplNotApplyResult(inserted);
        }
    }

    @Override
    public SudzDbtUplInvDbtVarEnsureSnapshot findDbtUplInvDbtVarEnsureSnapshot(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String invDbtVar = q("invDbtVar");
        // #sudzEia + ctx: монолитный CTE с повторным инлайном existInvAll зависал на минуты.
        String sql = sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, q("invDbt"), q("DbtValue"))
                + "SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnDate, cidutCnInv, "
                + "       iKey, account_key, account_num, cnnKey, invNumKey, cn_s_org_key, idvvKey, "
                + "       CASE "
                + "         WHEN cnnKey IS NULL AND invNumKey IS NULL THEN N'both' "
                + "         WHEN cnnKey IS NULL THEN N'cnn' "
                + "         WHEN invNumKey IS NULL THEN N'invNum' "
                + "         ELSE N'missing' "
                + "       END AS kind "
                + "FROM ctx "
                + "WHERE (cnnKey IS NULL OR invNumKey IS NULL) "
                + "   OR (cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NULL) "
                + "ORDER BY cidutCnName, cidutCnInv, account_key, iKey "
                + "OPTION (RECOMPILE)";
        try (Connection connection = connectionFactory.createConnection()) {
            fillSudzEiaTemp(connection, unloadKey);
            List<SudzDbtUplInvDbtVarEnsureRow> missing = new ArrayList<>();
            List<SudzDbtUplInvDbtVarAmbiguousRow> ambiguous = new ArrayList<>();
            java.util.LinkedHashSet<String> ambiguousKeys = new java.util.LinkedHashSet<>();
            String bound = bindUnloadKeyLiterals(sql, unloadKey);
            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(bound)) {
                while (rs.next()) {
                    String kind = rs.getNString("kind");
                    if ("missing".equals(kind)) {
                        missing.add(mapInvDbtVarEnsureRow(rs));
                        continue;
                    }
                    String key = rs.getNString("cidutCnName") + "\0"
                            + rs.getNString("cidutCnInv") + "\0"
                            + rs.getInt("iKey") + "\0" + kind;
                    if (ambiguousKeys.add(key)) {
                        ambiguous.add(new SudzDbtUplInvDbtVarAmbiguousRow(
                                rs.getNString("cidutCnName"),
                                rs.getNString("cidutCnInv"),
                                rs.getInt("iKey"),
                                kind
                        ));
                    }
                }
            }
            log.log(Level.INFO,
                    "findDbtUplInvDbtVarEnsureSnapshot unloadKey={0} missing={1} ambiguous={2}",
                    new Object[]{unloadKey, missing.size(), ambiguous.size()});
            return new SudzDbtUplInvDbtVarEnsureSnapshot(
                    List.copyOf(missing), List.copyOf(ambiguous));
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать invDbtVarEnsure snapshot unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public List<SudzDbtUplInvDbtVarEnsureRow> findDbtUplInvDbtVarEnsureMissing(int unloadKey) {
        return findDbtUplInvDbtVarEnsureSnapshot(unloadKey).missing();
    }

    @Override
    public List<SudzDbtUplInvDbtVarAmbiguousRow> findDbtUplInvDbtVarEnsureAmbiguous(int unloadKey) {
        return findDbtUplInvDbtVarEnsureSnapshot(unloadKey).ambiguous();
    }

    @Override
    public SudzDbtUplInvDbtVarEnsureApplyResult applyDbtUplInvDbtVarEnsure(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String invDbtVar = q("invDbtVar");
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                fillSudzEiaTemp(connection, unloadKey);
                insertInvNumAliasesFromEia(connection, now);
                // unloadKey + timestamp literals — Statement, иначе #sudzEia невидим.
                String bound = sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, q("invDbt"), q("DbtValue"))
                        .replace("t.cidutUnloadKey = ?", "t.cidutUnloadKey = " + unloadKey)
                        + sqlInsertInvDbtVarMissingFromCtx(
                                invDbtVar, "ctx", "'" + now.toLocalDateTime() + "'");
                try (Statement statement = connection.createStatement()) {
                    int inserted = statement.executeUpdate(bound);
                    connection.commit();
                    log.log(Level.INFO, "applyDbtUplInvDbtVarEnsure unloadKey={0} inserted={1}",
                            new Object[]{unloadKey, inserted});
                    return new SudzDbtUplInvDbtVarEnsureApplyResult(inserted);
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply invDbtVarEnsure unloadKey=" + unloadKey, exception);
        }
    }

    private static String sqlInsertInvDbtVarMissingFromCtx(
            String invDbtVar,
            String ctxSource,
            String timestampLiteral
    ) {
        return "INSERT INTO " + invDbtVar
                + "  (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry) "
                + "SELECT DISTINCT c.cnnKey, c.invNumKey, c.account_key, c.cn_s_org_key, "
                + "       CAST(" + timestampLiteral + " AS datetime2) "
                + "FROM " + ctxSource + " AS c "
                + "WHERE c.cnnKey IS NOT NULL AND c.invNumKey IS NOT NULL AND c.idvvKey IS NULL "
                + "  AND NOT EXISTS ( "
                + "    SELECT 1 FROM " + invDbtVar + " AS v "
                + "    WHERE v.idvvCnNum = c.cnnKey AND v.idvvInvNum = c.invNumKey "
                + "      AND v.idvvAccnt = c.account_key AND v.idvvCn_s_org = c.cn_s_org_key "
                + "  )";
    }

    private SudzDbtUplInvDbtVarEnsureApplyResult applyVarEnsureOnConnection(
            Connection connection,
            int unloadKey,
            String tbl,
            String invDbtVar,
            Timestamp now
    ) throws SQLException {
        String bound = sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, q("invDbt"), q("DbtValue"))
                .replace("t.cidutUnloadKey = ?", "t.cidutUnloadKey = " + unloadKey)
                + sqlInsertInvDbtVarMissingFromCtx(invDbtVar, "ctx", "'" + now.toLocalDateTime() + "'");
        try (Statement statement = connection.createStatement()) {
            int inserted = statement.executeUpdate(bound);
            log.log(Level.INFO, "applyVarEnsureOnConnection unloadKey={0} inserted={1}",
                    new Object[]{unloadKey, inserted});
            return new SudzDbtUplInvDbtVarEnsureApplyResult(inserted);
        }
    }

    @Override
    public int rebuildInvDbtDoubleQueue(int unloadKey, Integer fileKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String invDbtVar = q("invDbtVar");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String linkGroup = q("DbtSlotLinkGroup");
        String linkMember = q("DbtSlotLinkMember");
        String dbtValue = q("DbtValue");
        String queue = q("CnInvUplInvDbtDouble");
        String classifyCte = sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, invDbt, dbtValue)
                + ", "
                + "resolvedUnique AS ( "
                + "  SELECT * FROM ctx "
                + "  WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL "
                + "), "
                + "ambiguousIKeys AS ( "
                + "  SELECT DISTINCT iKey FROM ctx "
                + "  WHERE cnnKey IS NULL OR invNumKey IS NULL "
                + "), "
                + "multiCtxIKeys AS ( "
                + "  SELECT iKey FROM resolvedUnique "
                + "  GROUP BY iKey "
                + "  HAVING COUNT(DISTINCT CONCAT( "
                + "    CAST(cnnKey AS varchar(20)), N'|', "
                + "    CAST(invNumKey AS varchar(20)), N'|', "
                + "    CAST(account_key AS varchar(20)), N'|', "
                + "    CAST(cn_s_org_key AS varchar(20)))) > 1 "
                + ") "
                + sqlInvDbtHistMultiCtes(invDbt)
                + ", "
                + "valuedIKeys AS ( "
                + "  SELECT DISTINCT slot.idInv AS iKey "
                + "  FROM " + dbtValue + " AS dv "
                + "  INNER JOIN " + invDbt + " AS slot ON slot.idKey = dv.dvInvDbt "
                + "  WHERE dv.dvUpl = ? "
                + "), "
                + "tblRows AS ( "
                + "  SELECT a.cidutKey, a.cidutUnloadKey, a.cidutCnName, a.cidutCnInv, a.cidutDebt, "
                + "         a.cidutCntrPrtNum, "
                + "         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull, "
                + "         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull "
                + "  FROM " + tbl + " AS a "
                + "  WHERE a.cidutUnloadKey = ? "
                + "), "
                + "currentMulti AS ( "
                + "  SELECT e.iKey "
                + "  FROM tblRows AS t "
                + "  INNER JOIN #sudzEia AS e "
                + "    ON e.cidutCntrPrtNum = t.cidutCntrPrtNum "
                + "   AND e.cidutCnNameNull = t.cidutCnNameNull "
                + "   AND e.cidutCnDateNull = t.cidutCnDateNull "
                + "   AND e.cidutCnInvNull = t.cidutCnInvNull "
                + "  WHERE e.iKey IS NOT NULL "
                + "  GROUP BY e.iKey "
                + "  HAVING COUNT(DISTINCT t.cidutKey) > 1 "
                + ") "
                + sqlInvDbtF1MatchCtes(tbl, invDbt, invDbtDbt, linkGroup, linkMember, dbtValue, "a.cidutUnloadKey = ?")
                + ", "
                + "f1Eligible AS ( "
                + "  SELECT f.iKey, f.idInvDbt "
                + "  FROM f1Unique AS f "
                + "  WHERE EXISTS (SELECT 1 FROM resolvedUnique r WHERE r.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM ambiguousIKeys a WHERE a.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM multiCtxIKeys m WHERE m.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM currentMulti c WHERE c.iKey = f.iKey) "
                + "), "
                + "needQueue AS ( "
                + "  SELECT iKey, N'excel_unresolved' AS reason FROM ambiguousIKeys "
                + "  UNION "
                + "  SELECT iKey, N'multi' FROM multiCtxIKeys "
                + "  UNION "
                + "  SELECT iKey, N'multi' FROM histInvDbtMulti "
                + "  UNION "
                + "  SELECT iKey, N'multi' FROM histNamedAccMulti "
                + "  UNION "
                + "  SELECT iKey, N'multi' FROM histCidMulti "
                + "  UNION "
                + "  SELECT iKey, N'multi' FROM currentMulti "
                + "), "
                + "histInvDbtCnt AS ( "
                + "  SELECT idInv AS iKey, COUNT(*) AS cnt FROM " + invDbt + " GROUP BY idInv "
                + "), "
                + "histNamedCnt AS ( "
                + "  SELECT ci.ciInv AS iKey, COUNT(*) AS cnt "
                + "  FROM ags.cnInvAccnt AS a "
                + "  INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey "
                + "  INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey "
                + "  WHERE a.ciaName IS NOT NULL "
                + "  GROUP BY ci.ciInv "
                + "), "
                + "histCidMultiUplCnt AS ( "
                + "  SELECT y.iKey, COUNT(*) AS multiUplCnt "
                + "  FROM ( "
                + "    SELECT ci.ciInv AS iKey "
                + "    FROM ags.cn_inv_dbt AS d "
                + "    INNER JOIN ags.cnInvAccnt AS a ON a.ciaKey = d.cidCnInvAccntCtpt "
                + "    INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey "
                + "    INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey "
                + "    GROUP BY ci.ciInv, d.cn_inv_dbt_upl "
                + "    HAVING COUNT(*) > 1 "
                + "  ) AS y "
                + "  GROUP BY y.iKey "
                + "), "
                + "multiCtxCnt AS ( "
                + "  SELECT iKey, COUNT(DISTINCT CONCAT( "
                + "    CAST(cnnKey AS varchar(20)), N'|', "
                + "    CAST(invNumKey AS varchar(20)), N'|', "
                + "    CAST(account_key AS varchar(20)), N'|', "
                + "    CAST(cn_s_org_key AS varchar(20)))) AS ctxCnt "
                + "  FROM resolvedUnique "
                + "  GROUP BY iKey "
                + "), "
                + "currentTblCnt AS ( "
                + "  SELECT e.iKey, COUNT(DISTINCT t.cidutKey) AS rowCnt "
                + "  FROM tblRows AS t "
                + "  INNER JOIN #sudzEia AS e "
                + "    ON e.cidutCntrPrtNum = t.cidutCntrPrtNum "
                + "   AND e.cidutCnNameNull = t.cidutCnNameNull "
                + "   AND e.cidutCnDateNull = t.cidutCnDateNull "
                + "   AND e.cidutCnInvNull = t.cidutCnInvNull "
                + "  WHERE e.iKey IS NOT NULL "
                + "  GROUP BY e.iKey "
                + "), "
                + "ambiguousKind AS ( "
                + "  SELECT iKey, "
                + "    CASE "
                + "      WHEN MAX(CASE WHEN cnnKey IS NULL THEN 1 ELSE 0 END) = 1 "
                + "       AND MAX(CASE WHEN invNumKey IS NULL THEN 1 ELSE 0 END) = 1 "
                + "      THEN N'cnn+invNum' "
                + "      WHEN MAX(CASE WHEN cnnKey IS NULL THEN 1 ELSE 0 END) = 1 "
                + "      THEN N'cnn' "
                + "      ELSE N'invNum' "
                + "    END AS kind "
                + "  FROM ctx "
                + "  WHERE cnnKey IS NULL OR invNumKey IS NULL "
                + "  GROUP BY iKey "
                + "), "
                + "flaggedIKeys AS ( "
                + "  SELECT DISTINCT iKey FROM needQueue "
                + "), "
                + "detailByIKey AS ( "
                + "  SELECT k.iKey, "
                + "    CASE WHEN amb.iKey IS NOT NULL THEN N'excel_unresolved' ELSE N'multi' END AS reason, "
                + "    CAST( "
                + "      N'[queue.build]' + NCHAR(10) "
                + "      + CASE WHEN amb.iKey IS NOT NULL THEN "
                + "          N'Причина: Excel не сопоставлен ровно с одним cnNum/invNum (excel_unresolved)' + NCHAR(10) "
                + "        ELSE "
                + "          N'Причина: несколько долгов на одном СФ (multi)' + NCHAR(10) "
                + "        END "
                + "      + CASE WHEN amb.iKey IS NOT NULL THEN "
                + "          N'• Текст Excel не дал ровно одного совпадения: ' "
                + "          + CASE ISNULL(ak.kind, N'?') "
                + "              WHEN N'cnn' THEN N'договор (cnNum): 0 или >1 совпадений' "
                + "              WHEN N'invNum' THEN N'СФ (invNum): 0 или >1 совпадений' "
                + "              WHEN N'cnn+invNum' THEN N'и договор, и СФ (cnn+invNum)' "
                + "              ELSE ISNULL(ak.kind, N'?') END "
                + "          + NCHAR(10) ELSE N'' END "
                + "      + CASE WHEN mc.iKey IS NOT NULL THEN "
                + "          N'• В текущей выгрузке у СФ несколько разных контекстов 4FK: ' "
                + "          + CAST(ISNULL(mcc.ctxCnt, 0) AS nvarchar(20)) "
                + "          + N' (multi_ctx)' + NCHAR(10) ELSE N'' END "
                + "      + CASE WHEN hi.iKey IS NOT NULL THEN "
                + "          N'• Уже есть несколько слотов invDbt на этот СФ: ' "
                + "          + CAST(ISNULL(hic.cnt, 0) AS nvarchar(20)) "
                + "          + N' (hist_invDbt)' + NCHAR(10) ELSE N'' END "
                + "      + CASE WHEN hn.iKey IS NOT NULL THEN "
                + "          N'• В старой картотеке несколько именованных карточек (ciaName): ' "
                + "          + CAST(ISNULL(hnc.cnt, 0) AS nvarchar(20)) "
                + "          + N' (hist_named_cia)' + NCHAR(10) ELSE N'' END "
                + "      + CASE WHEN hc.iKey IS NOT NULL THEN "
                + "          N'• В прошлых выгрузках на этот СФ уже было >1 строки долга: ' "
                + "          + CAST(ISNULL(hcc.multiUplCnt, 0) AS nvarchar(20)) "
                + "          + N' выгрузок (hist_cid)' + NCHAR(10) ELSE N'' END "
                + "      + CASE WHEN cur.iKey IS NOT NULL THEN "
                + "          N'• В текущем Excel несколько строк на этот СФ: ' "
                + "          + CAST(ISNULL(ctc.rowCnt, 0) AS nvarchar(20)) "
                + "          + N' (current_tbl)' + NCHAR(10) ELSE N'' END "
                + "    AS nvarchar(max)) AS detailText "
                + "  FROM flaggedIKeys AS k "
                + "  LEFT JOIN ambiguousIKeys AS amb ON amb.iKey = k.iKey "
                + "  LEFT JOIN ambiguousKind AS ak ON ak.iKey = k.iKey "
                + "  LEFT JOIN multiCtxIKeys AS mc ON mc.iKey = k.iKey "
                + "  LEFT JOIN multiCtxCnt AS mcc ON mcc.iKey = k.iKey "
                + "  LEFT JOIN histInvDbtMulti AS hi ON hi.iKey = k.iKey "
                + "  LEFT JOIN histInvDbtCnt AS hic ON hic.iKey = k.iKey "
                + "  LEFT JOIN histNamedAccMulti AS hn ON hn.iKey = k.iKey "
                + "  LEFT JOIN histNamedCnt AS hnc ON hnc.iKey = k.iKey "
                + "  LEFT JOIN histCidMulti AS hc ON hc.iKey = k.iKey "
                + "  LEFT JOIN histCidMultiUplCnt AS hcc ON hcc.iKey = k.iKey "
                + "  LEFT JOIN currentMulti AS cur ON cur.iKey = k.iKey "
                + "  LEFT JOIN currentTblCnt AS ctc ON ctc.iKey = k.iKey "
                + "), "
                + "needQueueBest AS ( "
                + "  SELECT n.iKey, MIN(n.reason) AS reason "
                + "  FROM needQueue AS n "
                + "  WHERE NOT EXISTS (SELECT 1 FROM valuedIKeys v WHERE v.iKey = n.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM f1Eligible f WHERE f.iKey = n.iKey) "
                + "  GROUP BY n.iKey "
                + "), "
                + "rowMatch AS ( "
                + "  SELECT t.cidutKey, t.cidutCnName, t.cidutCnInv, t.cidutDebt, "
                + "         e.iKey, c.idvvKey, n.reason, d.detailText "
                + "  FROM tblRows AS t "
                + "  INNER JOIN #sudzEia AS e "
                + "    ON e.cidutCntrPrtNum = t.cidutCntrPrtNum "
                + "   AND e.cidutCnNameNull = t.cidutCnNameNull "
                + "   AND e.cidutCnDateNull = t.cidutCnDateNull "
                + "   AND e.cidutCnInvNull = t.cidutCnInvNull "
                + "  INNER JOIN needQueueBest AS n ON n.iKey = e.iKey "
                + "  LEFT JOIN detailByIKey AS d ON d.iKey = e.iKey "
                + "  LEFT JOIN resolvedUnique AS c "
                + "    ON c.iKey = e.iKey "
                + "   AND c.cidutCntrPrtNum = e.cidutCntrPrtNum "
                + "   AND ((c.cidutCnInv = e.cidutCnInv) "
                + "     OR (c.cidutCnInv IS NULL AND e.cidutCnInv IS NULL)) "
                + ") ";
        String materializeSql = classifyCte
                + "SELECT cidutKey, cidutCnName, cidutCnInv, cidutDebt, iKey, idvvKey, reason, detailText "
                + "INTO #rowMatch FROM rowMatch; "
                + "SELECT iKey, reason, detailText INTO #invDbtQDetail FROM detailByIKey";
        String insertSql =
                "INSERT INTO " + queue
                        + " (ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey, ciudCnNum, ciudInvNum, "
                        + "  ciudDebt, ciudIdvvKey, ciudReason, ciudReasonDetail, ciudStatus) "
                        + "SELECT deduped.cidutKey, ?, ?, deduped.iKey, deduped.cidutCnName, deduped.cidutCnInv, "
                        + "       deduped.cidutDebt, deduped.idvvKey, deduped.reason, deduped.detailText, 'open' "
                        + "FROM ( "
                        + "  SELECT r.cidutKey, r.cidutCnName, r.cidutCnInv, r.cidutDebt, r.iKey, r.idvvKey, "
                        + "         r.reason, r.detailText, "
                        + "         ROW_NUMBER() OVER (PARTITION BY r.cidutKey ORDER BY r.iKey, "
                        + "           ISNULL(r.idvvKey, 0), r.reason) AS rn "
                        + "  FROM #rowMatch AS r "
                        + ") AS deduped WHERE deduped.rn = 1";
        String refreshDetailSql =
                "UPDATE q SET ciudReasonDetail = d.detailText "
                        + "FROM " + queue + " AS q "
                        + "INNER JOIN #invDbtQDetail AS d ON d.iKey = q.ciudIKey "
                        + "WHERE q.ciudUnloadKey = " + unloadKey;
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                fillSudzEiaTemp(connection, unloadKey);
                try (Statement dropDetail = connection.createStatement()) {
                    dropDetail.executeUpdate(
                            "IF OBJECT_ID('tempdb..#invDbtQDetail') IS NOT NULL "
                                    + "DROP TABLE #invDbtQDetail; "
                                    + "IF OBJECT_ID('tempdb..#rowMatch') IS NOT NULL "
                                    + "DROP TABLE #rowMatch");
                }
                try (PreparedStatement del = connection.prepareStatement(
                        "DELETE FROM " + queue + " WHERE ciudUnloadKey = ?")) {
                    del.setInt(1, unloadKey);
                    int deleted = del.executeUpdate();
                    log.log(Level.INFO,
                            "CnInvUplInvDbtDouble cleared unloadKey={0} deleted={1}",
                            new Object[]{unloadKey, deleted});
                }
                String fileLit = fileKey == null ? "NULL" : Integer.toString(fileKey);
                String boundMaterialize = materializeSql
                        .replace("t.cidutUnloadKey = ?", "t.cidutUnloadKey = " + unloadKey)
                        .replace("a.cidutUnloadKey = ?", "a.cidutUnloadKey = " + unloadKey)
                        .replace("dv.dvUpl = ?", "dv.dvUpl = " + unloadKey);
                String boundInsert = insertSql.replace("?, ?", fileLit + ", " + unloadKey);
                try (Statement stmt = connection.createStatement()) {
                    stmt.executeUpdate(boundMaterialize);
                    int n = stmt.executeUpdate(boundInsert);
                    int refreshed = stmt.executeUpdate(refreshDetailSql);
                    connection.commit();
                    log.log(Level.INFO,
                            "CnInvUplInvDbtDouble filled unloadKey={0} inserted={1} detailRefresh={2}",
                            new Object[]{unloadKey, n, refreshed});
                    return n;
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось пересобрать CnInvUplInvDbtDouble unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplInvDbtLoadApplyResult runInvDbtLoadPhase(int unloadKey, Integer fileKey, boolean flLoad) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        long t0 = System.nanoTime();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                dropInvDbtLoadTemps(connection);
                fillSudzEiaTemp(connection, unloadKey);
                Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                insertInvNumAliasesFromEia(connection, now);
                String tbl = q("CnInvDbtUplTbl");
                String invDbtVar = q("invDbtVar");
                String invDbt = q("invDbt");
                materializeInvDbtCtxTemp(connection, unloadKey, tbl, invDbtVar, invDbt, q("DbtValue"));
                int queuedCount = rebuildInvDbtDoubleQueueOnConnection(connection, unloadKey, fileKey, true);
                SudzDbtUplInvDbtLoadApplyResult result = flLoad
                        ? applyInvDbtLoadUnambiguousOnConnection(connection, unloadKey, now, queuedCount)
                        : new SudzDbtUplInvDbtLoadApplyResult(0, 0, 0, queuedCount);
                connection.commit();
                long ms = (System.nanoTime() - t0) / 1_000_000L;
                log.log(Level.INFO,
                        "runInvDbtLoadPhase unloadKey={0} flLoad={1} queued={2} totalMs={3}",
                        new Object[]{unloadKey, flLoad, result.queuedCount(), ms});
                return result;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить invDbtLoad phase unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplAccSmplVarInvPhaseResult runAccSmplVarInvDbtPhase(
            int unloadKey,
            Integer fileKey,
            boolean flLoad
    ) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        long t0 = System.nanoTime();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                dropInvDbtLoadTemps(connection);
                fillSudzEiaTemp(connection, unloadKey);
                Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                SudzDbtUplAccSmplNotApplyResult accSmpl = null;
                if (flLoad) {
                    accSmpl = applyAccSmplOnConnection(connection, unloadKey, now);
                }
                insertInvNumAliasesFromEia(connection, now);
                String tbl = q("CnInvDbtUplTbl");
                String invDbtVar = q("invDbtVar");
                String invDbt = q("invDbt");
                SudzDbtUplInvDbtVarEnsureApplyResult varEnsure = null;
                if (flLoad) {
                    varEnsure = applyVarEnsureOnConnection(connection, unloadKey, tbl, invDbtVar, now);
                }
                materializeInvDbtCtxTemp(
                        connection, unloadKey, tbl, invDbtVar, invDbt, q("DbtValue"));
                int queuedCount = rebuildInvDbtDoubleQueueOnConnection(connection, unloadKey, fileKey, true);
                SudzDbtUplInvDbtLoadApplyResult invDbtLoad = flLoad
                        ? applyInvDbtLoadUnambiguousOnConnection(connection, unloadKey, now, queuedCount)
                        : new SudzDbtUplInvDbtLoadApplyResult(0, 0, 0, queuedCount);
                connection.commit();
                long ms = (System.nanoTime() - t0) / 1_000_000L;
                log.log(Level.INFO,
                        "runAccSmplVarInvDbtPhase unloadKey={0} flLoad={1} accSmpl={2} var={3} "
                                + "invDbt={4} totalMs={5}",
                        new Object[]{
                                unloadKey,
                                flLoad,
                                accSmpl == null ? 0 : accSmpl.insertedCount(),
                                varEnsure == null ? 0 : varEnsure.insertedCount(),
                                invDbtLoad.insertedInvDbt(),
                                ms
                        });
                return new SudzDbtUplAccSmplVarInvPhaseResult(accSmpl, varEnsure, invDbtLoad);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить AccSmplVarInv phase unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplInvDbtLoadApplyResult applyDbtUplInvDbtLoadUnambiguous(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                dropInvDbtLoadTemps(connection);
                fillSudzEiaTemp(connection, unloadKey);
                Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                insertInvNumAliasesFromEia(connection, now);
                materializeInvDbtCtxTemp(
                        connection, unloadKey, q("CnInvDbtUplTbl"), q("invDbtVar"), q("invDbt"), q("DbtValue"));
                SudzDbtUplInvDbtLoadApplyResult result =
                        applyInvDbtLoadUnambiguousOnConnection(connection, unloadKey, now, -1);
                connection.commit();
                return result;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply invDbtLoad unloadKey=" + unloadKey, exception);
        }
    }

    /**
     * Apply однозначных invDbt/мостов/Value на подготовленном соединении
     * ({@code #sudzEia}, {@code #invDbtCtx}).
     *
     * @param queuedHint если &gt;= 0 — не пересчитывать очередь (уже rebuild в phase)
     */
    private SudzDbtUplInvDbtLoadApplyResult applyInvDbtLoadUnambiguousOnConnection(
            Connection connection,
            int unloadKey,
            Timestamp now,
            int queuedHint
    ) throws SQLException {
        String tbl = q("CnInvDbtUplTbl");
        String invDbtVar = q("invDbtVar");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String linkGroup = q("DbtSlotLinkGroup");
        String linkMember = q("DbtSlotLinkMember");
        String bridge = q("invDbtDbtVar");
        String dbtValue = q("DbtValue");
        String queue = q("CnInvUplInvDbtDouble");
        String tsLit = "'" + now.toLocalDateTime() + "'";
        String insertVarForCalm =
                sqlInsertInvDbtVarMissingFromCtx(invDbtVar, "#invDbtCtx", tsLit);
        int insertedVars;
        try (Statement ps = connection.createStatement()) {
            insertedVars = ps.executeUpdate(insertVarForCalm);
        }
        refreshInvDbtCtxIdvvKeys(connection, invDbtVar);
        materializeInvDbtLoadWorkset(
                connection, unloadKey, tbl, invDbt, invDbtDbt, linkGroup, linkMember, dbtValue, queue);
        String insertInvDbt =
                "INSERT INTO " + invDbt + " (idInv, idNum, idTimeOfEntry) "
                        + "SELECT c.iKey, 1, CAST(" + tsLit + " AS datetime2) "
                        + "FROM #calmOne AS c "
                        + "WHERE NOT EXISTS (SELECT 1 FROM " + invDbt + " d WHERE d.idInv = c.iKey)";
        String insertBridge =
                "INSERT INTO " + bridge + " (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry) "
                        + "SELECT d.idKey, c.idvvKey, CAST(" + tsLit + " AS datetime2) "
                        + "FROM #calmOne AS c "
                        + "INNER JOIN " + invDbt + " AS d ON d.idInv = c.iKey "
                        + "WHERE (SELECT COUNT(*) FROM " + invDbt + " x WHERE x.idInv = c.iKey) = 1 "
                        + "  AND NOT EXISTS ( "
                        + "    SELECT 1 FROM " + bridge + " b "
                        + "    WHERE b.iddvInvDbt = d.idKey AND b.iddvInvDbtVar = c.idvvKey "
                        + ")";
        String tblDebtApply = sqlTblDebtCrossApply(tbl, unloadKey, "c.iKey");
        String insertValue =
                "INSERT INTO " + dbtValue
                        + " (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,"
                        + "  dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry) "
                        + "SELECT d.idKey, c.idvvKey, " + unloadKey + ","
                        + " COALESCE(t.cidutDebt, CAST(0 AS money)),"
                        + " COALESCE(t.cidutDebtOverdue, CAST(0 AS money)),"
                        + " CAST(t.cidutFormtnDate AS date), CAST(t.cidutMatrtyDate AS date),"
                        + " COALESCE(NULLIF(LTRIM(RTRIM(t.cidutDoc)), N''), t.cidutCnInv), CAST("
                        + tsLit + " AS datetime2) "
                        + "FROM #calmOne AS c "
                        + "INNER JOIN " + invDbt + " AS d ON d.idInv = c.iKey "
                        + "INNER JOIN " + bridge + " AS b "
                        + "  ON b.iddvInvDbt = d.idKey AND b.iddvInvDbtVar = c.idvvKey "
                        + tblDebtApply
                        + "WHERE (SELECT COUNT(*) FROM " + invDbt + " x WHERE x.idInv = c.iKey) = 1 "
                        + "  AND NOT EXISTS ( "
                        + "    SELECT 1 FROM " + dbtValue + " dv "
                        + "    WHERE dv.dvInvDbt = d.idKey AND dv.dvUpl = " + unloadKey
                        + "  ) "
                        + "  AND " + sqlNoSiblingValueAtUpl(
                        invDbt, dbtValue, unloadKey, "d.idKey", "c.iKey",
                        "CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4))",
                        "#tblIKey");
        String insertBridgeF1 =
                "INSERT INTO " + bridge + " (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry) "
                        + "SELECT f.idInvDbt, f.idvvKey, CAST(" + tsLit + " AS datetime2) "
                        + "FROM #f1One AS f "
                        + "WHERE NOT EXISTS ( "
                        + "  SELECT 1 FROM " + bridge + " b "
                        + "  WHERE b.iddvInvDbt = f.idInvDbt AND b.iddvInvDbtVar = f.idvvKey "
                        + ")";
        String tblDebtApplyF1 = sqlTblDebtCrossApply(tbl, unloadKey, "f.iKey");
        String insertValueF1 =
                "INSERT INTO " + dbtValue
                        + " (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,"
                        + "  dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry) "
                        + "SELECT f.idInvDbt, f.idvvKey, " + unloadKey + ","
                        + " COALESCE(t.cidutDebt, CAST(0 AS money)),"
                        + " COALESCE(t.cidutDebtOverdue, CAST(0 AS money)),"
                        + " CAST(t.cidutFormtnDate AS date), CAST(t.cidutMatrtyDate AS date),"
                        + " COALESCE(NULLIF(LTRIM(RTRIM(t.cidutDoc)), N''), t.cidutCnInv), CAST("
                        + tsLit + " AS datetime2) "
                        + "FROM #f1One AS f "
                        + "INNER JOIN " + bridge + " AS b "
                        + "  ON b.iddvInvDbt = f.idInvDbt AND b.iddvInvDbtVar = f.idvvKey "
                        + tblDebtApplyF1
                        + "WHERE NOT EXISTS ( "
                        + "  SELECT 1 FROM " + dbtValue + " dv "
                        + "  WHERE dv.dvInvDbt = f.idInvDbt AND dv.dvUpl = " + unloadKey
                        + " ) "
                        + "  AND " + sqlNoSiblingValueAtUpl(
                        invDbt, dbtValue, unloadKey, "f.idInvDbt", "f.iKey",
                        "CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4))",
                        "#tblIKey");
        int insertedInvDbt;
        try (Statement ps = connection.createStatement()) {
            insertedInvDbt = ps.executeUpdate(insertInvDbt);
        }
        int insertedBridges;
        try (Statement ps = connection.createStatement()) {
            insertedBridges = ps.executeUpdate(insertBridge);
        }
        int insertedValues;
        try (Statement ps = connection.createStatement()) {
            insertedValues = ps.executeUpdate(insertValue);
        }
        int insertedBridgesF1;
        try (Statement ps = connection.createStatement()) {
            insertedBridgesF1 = ps.executeUpdate(insertBridgeF1);
        }
        int insertedValuesF1;
        try (Statement ps = connection.createStatement()) {
            insertedValuesF1 = ps.executeUpdate(insertValueF1);
        }
        insertedBridges += insertedBridgesF1;
        insertedValues += insertedValuesF1;
        try (PreparedStatement del = connection.prepareStatement(
                "DELETE q FROM " + queue + " AS q "
                        + "INNER JOIN " + invDbt + " AS slot ON slot.idInv = q.ciudIKey "
                        + "INNER JOIN " + dbtValue + " AS dv ON dv.dvInvDbt = slot.idKey "
                        + "WHERE q.ciudUnloadKey = ? AND dv.dvUpl = ?")) {
            del.setInt(1, unloadKey);
            del.setInt(2, unloadKey);
            del.executeUpdate();
        }
        int queuedCount = queuedHint;
        if (queuedCount < 0) {
            try (PreparedStatement ps = connection.prepareStatement(
                    "SELECT COUNT(*) FROM " + queue + " WHERE ciudUnloadKey = ?")) {
                ps.setInt(1, unloadKey);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    queuedCount = rs.getInt(1);
                }
            }
        }
        log.log(Level.INFO,
                "applyDbtUplInvDbtLoadUnambiguous unloadKey={0} vars={1} invDbt={2} bridges={3}"
                        + " values={4} f1Values={5} queued={6}",
                new Object[]{
                        unloadKey, insertedVars, insertedInvDbt, insertedBridges, insertedValues,
                        insertedValuesF1, queuedCount
                });
        return new SudzDbtUplInvDbtLoadApplyResult(
                insertedInvDbt, insertedBridges, insertedValues, queuedCount);
    }

    /** CROSS APPLY одной Tbl-строки по {@code iKey}. */
    private static String sqlTblDebtCrossApply(String tbl, int unloadKey, String iKeyCol) {
        return " CROSS APPLY ( "
                + "   SELECT TOP 1 a.cidutDebt, a.cidutDebtOverdue, a.cidutFormtnDate,"
                + "          a.cidutMatrtyDate, a.cidutDoc, a.cidutCnInv "
                + "   FROM " + tbl + " AS a "
                + "   INNER JOIN #sudzEia AS e "
                + "     ON e.cidutCntrPrtNum = a.cidutCntrPrtNum "
                + "    AND e.cidutCnNameNull = CASE "
                + "          WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "          THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END "
                + "    AND e.cidutCnDateNull = CASE "
                + "          WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "          ELSE CAST(a.cidutCnDate AS date) END "
                + "    AND e.cidutCnInvNull = CASE "
                + "          WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "          THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END "
                + "   WHERE a.cidutUnloadKey = " + unloadKey
                + "     AND e.iKey = " + iKeyCol + " "
                + "   ORDER BY a.cidutKey "
                + " ) AS t ";
    }

    /**
     * Пересборка очереди на открытом соединении; {@code ctx} из {@code #invDbtCtx} если {@code ctxFromTemp}.
     */
    private int rebuildInvDbtDoubleQueueOnConnection(
            Connection connection,
            int unloadKey,
            Integer fileKey,
            boolean ctxFromTemp
    ) throws SQLException {
        if (!ctxFromTemp) {
            fillSudzEiaTemp(connection, unloadKey);
        }
        String tbl = q("CnInvDbtUplTbl");
        String invDbtVar = q("invDbtVar");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String linkGroup = q("DbtSlotLinkGroup");
        String linkMember = q("DbtSlotLinkMember");
        String dbtValue = q("DbtValue");
        String queue = q("CnInvUplInvDbtDouble");
        String ctxPrefix = ctxFromTemp
                ? sqlInvDbtCtxFromTempCte()
                : bindUnloadKeyLiterals(
                sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, invDbt, dbtValue), unloadKey);
        if (!ctxFromTemp) {
            try (Statement statement = connection.createStatement()) {
                statement.executeUpdate(
                        bindUnloadKeyLiterals(
                                sqlDbtUplInvDbtVarEnsureCte(tbl, invDbtVar, invDbt, dbtValue)
                                        + "SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnDate, "
                                        + "       cidutCnInv, iKey, cn_s_org_key, account_key, account_num, "
                                        + "       cnnKey, invNumKey, idvvKey "
                                        + "INTO #invDbtCtx FROM ctx OPTION (RECOMPILE)",
                                unloadKey));
            }
            ctxPrefix = sqlInvDbtCtxFromTempCte();
        }
        String classifyCte = ctxPrefix
                + ", resolvedUnique AS ( SELECT * FROM ctx WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL ), "
                + "ambiguousIKeys AS ( SELECT DISTINCT iKey FROM ctx WHERE cnnKey IS NULL OR invNumKey IS NULL ), "
                + "multiCtxIKeys AS ( SELECT iKey FROM resolvedUnique GROUP BY iKey "
                + "  HAVING COUNT(DISTINCT CONCAT(CAST(cnnKey AS varchar(20)), N'|', "
                + "    CAST(invNumKey AS varchar(20)), N'|', CAST(account_key AS varchar(20)), N'|', "
                + "    CAST(cn_s_org_key AS varchar(20)))) > 1 ) "
                + sqlInvDbtHistMultiCtes(invDbt)
                + ", valuedIKeys AS ( SELECT DISTINCT slot.idInv AS iKey FROM " + dbtValue + " AS dv "
                + "  INNER JOIN " + invDbt + " AS slot ON slot.idKey = dv.dvInvDbt WHERE dv.dvUpl = " + unloadKey + " ), "
                + "tblRows AS ( SELECT a.cidutKey, a.cidutCnName, a.cidutCnInv, a.cidutDebt, a.cidutCntrPrtNum, "
                + "  CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull, "
                + "  CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull, "
                + "  CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull "
                + "  FROM " + tbl + " AS a WHERE a.cidutUnloadKey = " + unloadKey + " ), "
                + "currentMulti AS ( SELECT e.iKey FROM tblRows AS t INNER JOIN #sudzEia AS e "
                + "  ON e.cidutCntrPrtNum = t.cidutCntrPrtNum AND e.cidutCnNameNull = t.cidutCnNameNull "
                + " AND e.cidutCnDateNull = t.cidutCnDateNull AND e.cidutCnInvNull = t.cidutCnInvNull "
                + "  WHERE e.iKey IS NOT NULL GROUP BY e.iKey HAVING COUNT(DISTINCT t.cidutKey) > 1 ) "
                + sqlInvDbtF1MatchCtes(tbl, invDbt, invDbtDbt, linkGroup, linkMember, dbtValue,
                "a.cidutUnloadKey = " + unloadKey)
                + ", f1Eligible AS ( SELECT f.iKey, f.idInvDbt FROM f1Unique AS f "
                + "  WHERE EXISTS (SELECT 1 FROM resolvedUnique r WHERE r.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM ambiguousIKeys a WHERE a.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM multiCtxIKeys m WHERE m.iKey = f.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM currentMulti c WHERE c.iKey = f.iKey) ), "
                + "needQueue AS ( SELECT iKey, N'excel_unresolved' AS reason FROM ambiguousIKeys UNION "
                + "  SELECT iKey, N'multi' FROM multiCtxIKeys UNION SELECT iKey, N'multi' FROM histInvDbtMulti UNION "
                + "  SELECT iKey, N'multi' FROM histNamedAccMulti UNION SELECT iKey, N'multi' FROM histCidMulti UNION "
                + "  SELECT iKey, N'multi' FROM currentMulti ), "
                + "needQueueBest AS ( SELECT n.iKey, MIN(n.reason) AS reason FROM needQueue AS n "
                + "  WHERE NOT EXISTS (SELECT 1 FROM valuedIKeys v WHERE v.iKey = n.iKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM f1Eligible f WHERE f.iKey = n.iKey) GROUP BY n.iKey ), "
                + "rowMatch AS ( SELECT t.cidutKey, t.cidutCnName, t.cidutCnInv, t.cidutDebt, e.iKey, c.idvvKey, "
                + "  n.reason, CAST(N'[queue.build]' AS nvarchar(max)) AS detailText "
                + "  FROM tblRows AS t INNER JOIN #sudzEia AS e "
                + "  ON e.cidutCntrPrtNum = t.cidutCntrPrtNum AND e.cidutCnNameNull = t.cidutCnNameNull "
                + " AND e.cidutCnDateNull = t.cidutCnDateNull AND e.cidutCnInvNull = t.cidutCnInvNull "
                + "  INNER JOIN needQueueBest AS n ON n.iKey = e.iKey "
                + "  LEFT JOIN resolvedUnique AS c ON c.iKey = e.iKey AND c.cidutCntrPrtNum = e.cidutCntrPrtNum "
                + "   AND ((c.cidutCnInv = e.cidutCnInv) OR (c.cidutCnInv IS NULL AND e.cidutCnInv IS NULL)) ) ";
        String materializeSql = classifyCte
                + "SELECT cidutKey, cidutCnName, cidutCnInv, cidutDebt, iKey, idvvKey, reason, detailText "
                + "INTO #rowMatch FROM rowMatch";
        String fileLit = fileKey == null ? "NULL" : Integer.toString(fileKey);
        String insertSql =
                "INSERT INTO " + queue
                        + " (ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey, ciudCnNum, ciudInvNum, "
                        + "  ciudDebt, ciudIdvvKey, ciudReason, ciudReasonDetail, ciudStatus) "
                        + "SELECT deduped.cidutKey, " + fileLit + ", " + unloadKey + ", deduped.iKey, "
                        + "       deduped.cidutCnName, deduped.cidutCnInv, deduped.cidutDebt, deduped.idvvKey, "
                        + "       deduped.reason, deduped.detailText, 'open' "
                        + "FROM ( "
                        + "  SELECT r.cidutKey, r.cidutCnName, r.cidutCnInv, r.cidutDebt, r.iKey, r.idvvKey, "
                        + "         r.reason, r.detailText, "
                        + "         ROW_NUMBER() OVER (PARTITION BY r.cidutKey ORDER BY r.iKey, "
                        + "           ISNULL(r.idvvKey, 0), r.reason) AS rn "
                        + "  FROM #rowMatch AS r "
                        + ") AS deduped WHERE deduped.rn = 1";
        try (Statement dropDetail = connection.createStatement()) {
            dropDetail.executeUpdate(
                    "IF OBJECT_ID('tempdb..#rowMatch') IS NOT NULL DROP TABLE #rowMatch");
        }
        try (PreparedStatement del = connection.prepareStatement(
                "DELETE FROM " + queue + " WHERE ciudUnloadKey = ?")) {
            del.setInt(1, unloadKey);
            int deleted = del.executeUpdate();
            log.log(Level.INFO,
                    "CnInvUplInvDbtDouble cleared unloadKey={0} deleted={1}",
                    new Object[]{unloadKey, deleted});
        }
        try (Statement stmt = connection.createStatement()) {
            stmt.executeUpdate(materializeSql);
            int n = stmt.executeUpdate(insertSql);
            log.log(Level.INFO,
                    "CnInvUplInvDbtDouble filled unloadKey={0} inserted={1}",
                    new Object[]{unloadKey, n});
            return n;
        }
    }
    /**
     * CTE классификации слотов upl с {@code DbtValue} без {@code invDbtDbt} (C1 / D7).
     *
     * @param dbtValue квалифицированное имя {@code DbtValue}
     * @param invDbt квалифицированное имя {@code invDbt}
     * @param invDbtDbt квалифицированное имя {@code invDbtDbt}
     * @param uplPred предикат upl ({@code dv.dvUpl = …})
     * @return фрагмент {@code WITH needBridge AS (…), …}
     */
    private static String sqlInvDbtDbtEnsureCtes(
            String dbtValue,
            String invDbt,
            String invDbtDbt,
            String linkGroup,
            String linkMember,
            String uplPred
    ) {
        return ""
                + "WITH needBridge AS ( "
                + "  SELECT dv.dvInvDbt AS slotKey, d.idInv AS iKey, "
                + "         CAST(dv.dvTtl AS decimal(19,4)) AS debt "
                + "  FROM " + dbtValue + " AS dv "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = dv.dvInvDbt "
                + "  WHERE " + uplPred
                + "    AND NOT EXISTS ( "
                + "      SELECT 1 FROM " + invDbtDbt + " AS idd WHERE idd.iddInvDbt = dv.dvInvDbt "
                + "    ) "
                + "), "
                + "lPick AS ( "
                + "  SELECT n.slotKey, g.canonicalDbtKey AS dbtKey "
                + "  FROM needBridge AS n "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = n.slotKey "
                + "  INNER JOIN " + linkMember + " AS m ON m.iKey = d.idInv AND m.idNum = d.idNum "
                + "  INNER JOIN " + linkGroup + " AS g ON g.lid = m.lid AND g.dslgStatus = N'active' "
                + "  WHERE g.canonicalDbtKey IS NOT NULL "
                + "), "
                + "f1Cand AS ( "
                + "  SELECT n.slotKey, idd.iddDbt AS dbtKey "
                + "  FROM needBridge AS n "
                + "  INNER JOIN " + invDbt + " AS d2 ON d2.idInv = n.iKey AND d2.idKey <> n.slotKey "
                + "  INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = d2.idKey "
                + "  INNER JOIN " + dbtValue + " AS dv2 ON dv2.dvInvDbt = d2.idKey "
                + "  WHERE ABS(CAST(dv2.dvTtl AS decimal(19,4)) - n.debt) "
                + "        <= CAST(0.01 AS decimal(19,4)) "
                + "), "
                + "f1Pick AS ( "
                + "  SELECT slotKey, MIN(dbtKey) AS dbtKey "
                + "  FROM f1Cand "
                + "  GROUP BY slotKey "
                + "  HAVING COUNT(DISTINCT dbtKey) = 1 "
                + "), "
                + "hasSiblingBridge AS ( "
                + "  SELECT DISTINCT n.slotKey "
                + "  FROM needBridge AS n "
                + "  INNER JOIN " + invDbt + " AS d2 ON d2.idInv = n.iKey AND d2.idKey <> n.slotKey "
                + "  INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = d2.idKey "
                + "), "
                + "newDbt AS ( "
                + "  SELECT n.slotKey, n.iKey "
                + "  FROM needBridge AS n "
                + "  WHERE NOT EXISTS (SELECT 1 FROM lPick AS l WHERE l.slotKey = n.slotKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM f1Pick AS f WHERE f.slotKey = n.slotKey) "
                + "    AND NOT EXISTS (SELECT 1 FROM hasSiblingBridge AS h WHERE h.slotKey = n.slotKey) "
                + "), "
                + "ambiguous AS ( "
                + "  SELECT n.slotKey "
                + "  FROM needBridge AS n "
                + "  WHERE NOT EXISTS (SELECT 1 FROM f1Pick AS f WHERE f.slotKey = n.slotKey) "
                + "    AND EXISTS (SELECT 1 FROM hasSiblingBridge AS h WHERE h.slotKey = n.slotKey) "
                + ") ";
    }

    @Override
    public SudzDbtUplInvDbtDbtEnsureSnapshot findDbtUplInvDbtDbtEnsureSnapshot(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String linkGroup = q("DbtSlotLinkGroup");
        String linkMember = q("DbtSlotLinkMember");
        String uplPred = "dv.dvUpl = " + unloadKey;
        String sql = sqlInvDbtDbtEnsureCtes(dbtValue, invDbt, invDbtDbt, linkGroup, linkMember, uplPred)
                + "SELECT "
                + "  (SELECT COUNT(*) FROM needBridge) AS missingBridge, "
                + "  (SELECT COUNT(*) FROM f1Pick) AS f1Ready, "
                + "  (SELECT COUNT(*) FROM newDbt) AS newReady, "
                + "  (SELECT COUNT(*) FROM ambiguous) AS ambiguous";
        try (Connection connection = connectionFactory.createConnection();
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(sql)) {
            rs.next();
            return new SudzDbtUplInvDbtDbtEnsureSnapshot(
                    rs.getInt("missingBridge"),
                    rs.getInt("f1Ready"),
                    rs.getInt("newReady"),
                    rs.getInt("ambiguous"));
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось снять snapshot invDbtDbtEnsure unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplInvDbtDbtEnsureApplyResult applyDbtUplInvDbtDbtEnsure(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        String dbt = q("Dbt");
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String linkGroup = q("DbtSlotLinkGroup");
        String linkMember = q("DbtSlotLinkMember");
        String uplPred = "dv.dvUpl = " + unloadKey;
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        String tsLit = "'" + now.toLocalDateTime() + "'";
        String ctes = sqlInvDbtDbtEnsureCtes(dbtValue, invDbt, invDbtDbt, linkGroup, linkMember, uplPred);
        SudzDbtUplInvDbtDbtEnsureSnapshot before = findDbtUplInvDbtDbtEnsureSnapshot(unloadKey);
        String lPickInsert = ctes
                + "INSERT INTO " + invDbtDbt + " (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry) "
                + "SELECT d.idInv, l.dbtKey, l.slotKey, CAST(" + tsLit + " AS datetime2) "
                + "FROM lPick AS l "
                + "INNER JOIN " + invDbt + " AS d ON d.idKey = l.slotKey";
        String f1Insert = ctes
                + "INSERT INTO " + invDbtDbt + " (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry) "
                + "SELECT d.idInv, f.dbtKey, f.slotKey, CAST(" + tsLit + " AS datetime2) "
                + "FROM f1Pick AS f "
                + "INNER JOIN " + invDbt + " AS d ON d.idKey = f.slotKey";
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int reusedL;
                try (Statement ps = connection.createStatement()) {
                    reusedL = ps.executeUpdate(lPickInsert);
                }
                int reusedF1;
                try (Statement ps = connection.createStatement()) {
                    reusedF1 = ps.executeUpdate(f1Insert);
                }
                List<int[]> newRows = new ArrayList<>();
                String newSql = ctes + "SELECT slotKey, iKey FROM newDbt ORDER BY slotKey";
                try (Statement ps = connection.createStatement();
                     ResultSet rs = ps.executeQuery(newSql)) {
                    while (rs.next()) {
                        newRows.add(new int[]{rs.getInt("slotKey"), rs.getInt("iKey")});
                    }
                }
                int insertedDbt = 0;
                for (int[] row : newRows) {
                    int slotKey = row[0];
                    int iKey = row[1];
                    int dbtKey;
                    try (PreparedStatement ins = connection.prepareStatement(
                            "INSERT INTO " + dbt
                                    + " (dbtTimeOfEntry, dbtNote) VALUES (?, ?)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        ins.setTimestamp(1, now);
                        ins.setString(2, "C1-upl=" + unloadKey);
                        ins.executeUpdate();
                        dbtKey = readGeneratedKey(ins, "Не удалось получить dbtKey");
                    }
                    try (PreparedStatement br = connection.prepareStatement(
                            "INSERT INTO " + invDbtDbt
                                    + " (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry) VALUES (?, ?, ?, ?)")) {
                        br.setInt(1, iKey);
                        br.setInt(2, dbtKey);
                        br.setInt(3, slotKey);
                        br.setTimestamp(4, now);
                        br.executeUpdate();
                    }
                    insertedDbt++;
                }
                int skippedAmbiguous = before.ambiguous();
                connection.commit();
                int insertedBridges = reusedL + reusedF1 + insertedDbt;
                log.log(Level.INFO,
                        "applyDbtUplInvDbtDbtEnsure unloadKey={0} lPick={1} f1={2} newDbt={3} bridges={4} ambiguous={5}",
                        new Object[]{unloadKey, reusedL, reusedF1, insertedDbt, insertedBridges, skippedAmbiguous});
                return new SudzDbtUplInvDbtDbtEnsureApplyResult(
                        reusedF1 + reusedL, insertedDbt, insertedBridges, skippedAmbiguous);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить apply invDbtDbtEnsure unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public Optional<Integer> findBaseUplForCurr(int unloadKey, int yrKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        if (yrKey <= 0) {
            throw new IllegalArgumentException("yrKey должен быть положительным: " + yrKey);
        }
        String sql = "SELECT y.cn_inv_dbt_upl AS baseUpl "
                + "FROM " + q("yr") + " AS y "
                + "INNER JOIN " + q("yr_upl_p") + " AS yp "
                + "  ON yp.yr_upl_p_yr = y.yr_key AND yp.cn_inv_dbt_upl = ? "
                + "WHERE y.yr_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            statement.setInt(2, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(rs.getInt("baseUpl"));
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось определить base upl для unloadKey="
                    + unloadKey + ", yrKey=" + yrKey, exception);
        }
    }

    @Override
    public List<Integer> findYearKeysForUpl(int uplKey) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        String sql = "SELECT DISTINCT yp.yr_upl_p_yr AS yrKey "
                + "FROM " + q("yr_upl_p") + " AS yp "
                + "WHERE yp.cn_inv_dbt_upl = ? "
                + "ORDER BY yp.yr_upl_p_yr";
        List<Integer> result = new ArrayList<>();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(rs.getInt("yrKey"));
                }
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось получить года для uplKey=" + uplKey, exception);
        }
        return List.copyOf(result);
    }

    /**
     * JOIN Tbl ↔ {@code #sudzEia} (нормализация null/пусто как в воронке).
     *
     * @return SQL-фрагмент {@code INNER JOIN #sudzEia AS e ON …}
     */
    private static String sqlTblSudzEiaJoin() {
        return ""
                + " INNER JOIN #sudzEia AS e "
                + "   ON e.cidutCntrPrtNum = a.cidutCntrPrtNum "
                + "  AND e.cidutCnNameNull = CASE "
                + "        WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' "
                + "        THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END "
                + "  AND e.cidutCnDateNull = CASE "
                + "        WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "        ELSE CAST(a.cidutCnDate AS date) END "
                + "  AND e.cidutCnInvNull = CASE "
                + "        WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' "
                + "        THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END ";
    }

    /**
     * CTE C2: исчезновение base→curr, tail, sum-match P1 (ожидает {@code #sudzEia}).
     *
     * @param dbtValue {@code DbtValue}
     * @param invDbt {@code invDbt}
     * @param invDbtDbt {@code invDbtDbt}
     * @param bridge {@code invDbtDbtVar}
     * @param tbl {@code CnInvDbtUplTbl}
     * @param currUpl текущая выгрузка
     * @param baseUpl базовая выгрузка года
     * @return фрагмент {@code WITH baseValues AS (…), …}
     */
    private static String sqlDbtValueLoadCoreCtes(
            String dbtValue,
            String invDbt,
            String invDbtDbt,
            String bridge,
            String invDbtVar,
            String tbl,
            int currUpl,
            int baseUpl
    ) {
        String eiaJoin = sqlTblSudzEiaJoin();
        return ""
                + "WITH baseValues AS ( "
                + "  SELECT dv.dvInvDbt AS slotKey, idd.iddDbt AS dbtKey, d.idInv AS iKey, "
                + "         CAST(dv.dvTtl AS decimal(19,4)) AS debt, "
                + "         CAST(dv.dvOverd AS decimal(19,4)) AS overd "
                + "  FROM " + dbtValue + " AS dv "
                + "  INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = dv.dvInvDbt "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = dv.dvInvDbt "
                + "  WHERE dv.dvUpl = " + baseUpl
                + "), "
                + "disappeared AS ( "
                + "  SELECT bv.* "
                + "  FROM baseValues AS bv "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " AS dv2 "
                + "    WHERE dv2.dvInvDbt = bv.slotKey AND dv2.dvUpl = " + currUpl
                + "  ) "
                + "), "
                + "matchSums AS ( "
                + "  SELECT dbtKey, slotKey, iKey, debt AS matchSum, CAST(N'ttl' AS varchar(8)) AS sumKind "
                + "  FROM disappeared "
                + "  UNION ALL "
                + "  SELECT dbtKey, slotKey, iKey, overd, CAST(N'overd' AS varchar(8)) "
                + "  FROM disappeared "
                + "  WHERE overd IS NOT NULL AND overd > CAST(0 AS decimal(19,4)) "
                + "), "
                + "baseCtx AS ( "
                + "  SELECT d.slotKey, d.dbtKey, d.iKey, "
                + "         cn.cnnNum AS baseCnNum, inv.inNum AS baseInvNum "
                + "  FROM disappeared AS d "
                + "  INNER JOIN " + dbtValue + " AS dv "
                + "    ON dv.dvInvDbt = d.slotKey AND dv.dvUpl = " + baseUpl
                + "  INNER JOIN " + invDbtVar + " AS v ON v.idvvKey = dv.dvInvDbtVar "
                + "  LEFT JOIN ags.cnNum AS cn ON cn.cnnKey = v.idvvCnNum "
                + "  LEFT JOIN ags.invNum AS inv ON inv.inKey = v.idvvInvNum "
                + "), "
                + "tblCurr AS ( "
                + "  SELECT a.cidutKey, e.iKey, "
                + "         CAST(a.cidutDebt AS decimal(19,4)) AS debt, "
                + "         a.cidutCnName, a.cidutCnInv "
                + "  FROM " + tbl + " AS a "
                + eiaJoin
                + "  WHERE a.cidutUnloadKey = " + currUpl + " AND e.iKey IS NOT NULL "
                + "), "
                + "tblIKey AS ( "
                + "  SELECT iKey, COUNT(DISTINCT cidutKey) AS rowCnt "
                + "  FROM tblCurr "
                + "  GROUP BY iKey "
                + "), "
                + "p1Cand AS ( "
                + "  SELECT ms.dbtKey, ms.slotKey, ms.iKey AS baseIKey, ms.matchSum, ms.sumKind, "
                + "         t.cidutKey, t.iKey AS candIKey, t.debt AS candDebt, "
                + "         t.cidutCnName, t.cidutCnInv "
                + "  FROM matchSums AS ms "
                + "  INNER JOIN tblCurr AS t "
                + "    ON ABS(t.debt - ms.matchSum) <= CAST(0.01 AS decimal(19,4)) "
                + "), "
                + "p1Grouped AS ( "
                + "  SELECT dbtKey, sumKind, COUNT(DISTINCT cidutKey) AS candCnt "
                + "  FROM p1Cand "
                + "  GROUP BY dbtKey, sumKind "
                + "), "
                + "p1None AS ( "
                + "  SELECT ms.dbtKey, ms.slotKey, ms.iKey AS baseIKey, ms.matchSum, ms.sumKind "
                + "  FROM matchSums AS ms "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM p1Cand AS pc "
                + "    WHERE pc.dbtKey = ms.dbtKey AND pc.sumKind = ms.sumKind "
                + "  ) "
                + "), "
                + "tailSlots AS ( "
                + "  SELECT idd.iddInvDbt AS slotKey, d.idInv AS iKey, "
                + "         COUNT(DISTINCT b.iddvInvDbtVar) AS varCnt "
                + "  FROM " + invDbtDbt + " AS idd "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = idd.iddInvDbt "
                + "  INNER JOIN " + bridge + " AS b ON b.iddvInvDbt = idd.iddInvDbt "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " AS dv "
                + "    WHERE dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = " + currUpl
                + "  ) "
                + "    AND EXISTS ( "
                + "      SELECT 1 FROM " + tbl + " AS a "
                + eiaJoin
                + "      WHERE a.cidutUnloadKey = " + currUpl + " AND e.iKey = d.idInv "
                + "    ) "
                + "  GROUP BY idd.iddInvDbt, d.idInv "
                + "), "
                + "tailReady AS ( "
                + "  SELECT slotKey, iKey FROM tailSlots WHERE varCnt = 1 "
                + "), "
                + "tailAmbiguous AS ( "
                + "  SELECT slotKey FROM tailSlots WHERE varCnt > 1 "
                + ") ";
    }

    /**
     * CTE исчезновения base→curr без tail/P1.
     */
    private static String sqlDbtValueLoadDisappearedCte(
            String dbtValue,
            String invDbtDbt,
            String invDbt,
            int currUpl,
            int baseUpl
    ) {
        return ""
                + "WITH baseValues AS ( "
                + "  SELECT dv.dvInvDbt AS slotKey, idd.iddDbt AS dbtKey, d.idInv AS iKey, "
                + "         CAST(dv.dvTtl AS decimal(19,4)) AS debt, "
                + "         CAST(dv.dvOverd AS decimal(19,4)) AS overd "
                + "  FROM " + dbtValue + " AS dv "
                + "  INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = dv.dvInvDbt "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = dv.dvInvDbt "
                + "  WHERE dv.dvUpl = " + baseUpl
                + "), "
                + "disappeared AS ( "
                + "  SELECT bv.* "
                + "  FROM baseValues AS bv "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " AS dv2 "
                + "    WHERE dv2.dvInvDbt = bv.slotKey AND dv2.dvUpl = " + currUpl
                + "  ) "
                + ") ";
    }

    /**
     * CTE tail-слотов без base/disappeared (ожидает {@code #sudzEia}).
     */
    private static String sqlDbtValueLoadTailOnlyCtes(
            String dbtValue,
            String invDbt,
            String invDbtDbt,
            String bridge,
            String tbl,
            int currUpl
    ) {
        String eiaJoin = sqlTblSudzEiaJoin();
        return ""
                + "WITH tailSlots AS ( "
                + "  SELECT idd.iddInvDbt AS slotKey, d.idInv AS iKey, "
                + "         COUNT(DISTINCT b.iddvInvDbtVar) AS varCnt "
                + "  FROM " + invDbtDbt + " AS idd "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = idd.iddInvDbt "
                + "  INNER JOIN " + bridge + " AS b ON b.iddvInvDbt = idd.iddInvDbt "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " AS dv "
                + "    WHERE dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = " + currUpl
                + "  ) "
                + "    AND EXISTS ( "
                + "      SELECT 1 FROM " + tbl + " AS a "
                + eiaJoin
                + "      WHERE a.cidutUnloadKey = " + currUpl + " AND e.iKey = d.idInv "
                + "    ) "
                + "  GROUP BY idd.iddInvDbt, d.idInv "
                + "), "
                + "tailReady AS ( "
                + "  SELECT slotKey, iKey FROM tailSlots WHERE varCnt = 1 "
                + "), "
                + "tailAmbiguous AS ( "
                + "  SELECT slotKey FROM tailSlots WHERE varCnt > 1 "
                + ") ";
    }

    @Override
    public SudzDbtUplDbtValueLoadSnapshot findDbtUplDbtValueLoadSnapshot(int unloadKey, int yrKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        if (yrKey <= 0) {
            throw new IllegalArgumentException("yrKey должен быть положительным: " + yrKey);
        }
        Optional<Integer> baseOpt = findBaseUplForCurr(unloadKey, yrKey);
        if (baseOpt.isEmpty() || baseOpt.get().equals(unloadKey)) {
            int skipped = countDbtValuesOnUpl(unloadKey);
            int p1Open = countDbtP1Open(unloadKey);
            return new SudzDbtUplDbtValueLoadSnapshot(
                    baseOpt.orElse(null), skipped, 0, 0, 0,
                    countDbtP1Queued(unloadKey), p1Open);
        }
        int baseUpl = baseOpt.get();
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String bridge = q("invDbtDbtVar");
        String invDbtVar = q("invDbtVar");
        String tbl = q("CnInvDbtUplTbl");
        String ctes = sqlDbtValueLoadCoreCtes(
                dbtValue, invDbt, invDbtDbt, bridge, invDbtVar, tbl, unloadKey, baseUpl);
        String sql = ctes
                + "SELECT "
                + "  (SELECT COUNT(*) FROM " + dbtValue + " WHERE dvUpl = " + unloadKey + ") AS skippedValues, "
                + "  (SELECT COUNT(*) FROM tailReady) AS tailReady, "
                + "  (SELECT COUNT(*) FROM tailAmbiguous) AS tailAmbiguous, "
                + "  (SELECT COUNT(DISTINCT dbtKey) FROM disappeared) AS disappeared, "
                + "  (SELECT COUNT(*) FROM " + q("CnInvUplDbtP1")
                + "     WHERE cip1UnloadKey = " + unloadKey + ") AS p1Queued, "
                + "  (SELECT COUNT(*) FROM " + q("CnInvUplDbtP1")
                + "     WHERE cip1UnloadKey = " + unloadKey + " AND cip1Status = N'open') AS p1Open";
        try (Connection connection = connectionFactory.createConnection()) {
            fillSudzEiaTemp(connection, unloadKey);
            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(sql)) {
                rs.next();
                return new SudzDbtUplDbtValueLoadSnapshot(
                        baseUpl,
                        rs.getInt("skippedValues"),
                        rs.getInt("tailReady"),
                        rs.getInt("tailAmbiguous"),
                        rs.getInt("disappeared"),
                        rs.getInt("p1Queued"),
                        rs.getInt("p1Open"));
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось снять snapshot dbtValueLoad unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public int rebuildDbtP1Queue(int unloadKey, Integer fileKey, int yrKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        if (yrKey <= 0) {
            throw new IllegalArgumentException("yrKey должен быть положительным: " + yrKey);
        }
        Optional<Integer> baseOpt = findBaseUplForCurr(unloadKey, yrKey);
        if (baseOpt.isEmpty() || baseOpt.get().equals(unloadKey)) {
            deleteDbtP1ForUnload(unloadKey);
            return 0;
        }
        int baseUpl = baseOpt.get();
        String queue = q("CnInvUplDbtP1");
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String bridge = q("invDbtDbtVar");
        String invDbtVar = q("invDbtVar");
        String tbl = q("CnInvDbtUplTbl");
        String ctes = sqlDbtValueLoadCoreCtes(
                dbtValue, invDbt, invDbtDbt, bridge, invDbtVar, tbl, unloadKey, baseUpl);
        Integer dbtFileSql = fileKey == null ? null : fileKey;
        String fileLit = dbtFileSql == null ? "NULL" : String.valueOf(dbtFileSql);
        String detailCand = "N'[queue.build] исчез Dbt=' + CAST(pc.dbtKey AS nvarchar(20)) "
                + "+ N' sum=' + CAST(pc.matchSum AS nvarchar(32)) "
                + "+ N' → iKey=' + CAST(pc.candIKey AS nvarchar(20))";
        String detailNone = "N'[queue.build] исчез Dbt=' + CAST(n.dbtKey AS nvarchar(20)) "
                + "+ N' sum=' + CAST(n.matchSum AS nvarchar(32)) + N' — нет sum-match в Tbl'";
        String insertCand = ctes
                + "INSERT INTO " + queue + " ( "
                + "  cip1UnloadKey, cip1BaseUpl, cip1DbtFile, cip1DbtKey, cip1BaseSlotKey, cip1BaseIKey, "
                + "  cip1BaseCnNum, cip1BaseInvNum, cip1MatchSum, cip1SumKind, "
                + "  cip1CandCidut, cip1CandIKey, cip1CandCnNum, cip1CandInvNum, cip1CandDebt, "
                + "  cip1Reason, cip1ReasonDetail, cip1Status, cip1StatusAt "
                + ") "
                + "SELECT " + unloadKey + ", " + baseUpl + ", " + fileLit + ", "
                + "       pc.dbtKey, pc.slotKey, pc.baseIKey, "
                + "       bc.baseCnNum, bc.baseInvNum, pc.matchSum, pc.sumKind, "
                + "       pc.cidutKey, pc.candIKey, pc.cidutCnName, pc.cidutCnInv, pc.candDebt, "
                + "       CASE WHEN pg.candCnt = 1 THEN N'single' ELSE N'multi' END, "
                + "       " + detailCand + ", N'open', GETDATE() "
                + "FROM p1Cand AS pc "
                + "INNER JOIN p1Grouped AS pg "
                + "  ON pg.dbtKey = pc.dbtKey AND pg.sumKind = pc.sumKind "
                + "LEFT JOIN baseCtx AS bc ON bc.slotKey = pc.slotKey";
        String insertNone = ctes
                + "INSERT INTO " + queue + " ( "
                + "  cip1UnloadKey, cip1BaseUpl, cip1DbtFile, cip1DbtKey, cip1BaseSlotKey, cip1BaseIKey, "
                + "  cip1BaseCnNum, cip1BaseInvNum, cip1MatchSum, cip1SumKind, "
                + "  cip1Reason, cip1ReasonDetail, cip1Status, cip1StatusAt "
                + ") "
                + "SELECT " + unloadKey + ", " + baseUpl + ", " + fileLit + ", "
                + "       n.dbtKey, n.slotKey, n.baseIKey, "
                + "       bc.baseCnNum, bc.baseInvNum, n.matchSum, n.sumKind, "
                + "       N'none', " + detailNone + ", N'open', GETDATE() "
                + "FROM p1None AS n "
                + "LEFT JOIN baseCtx AS bc ON bc.slotKey = n.slotKey";
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                fillSudzEiaTemp(connection, unloadKey);
                deleteDbtP1OnConnection(connection, unloadKey);
                int inserted = 0;
                try (Statement ps = connection.createStatement()) {
                    inserted += ps.executeUpdate(insertCand);
                    inserted += ps.executeUpdate(insertNone);
                }
                connection.commit();
                log.log(Level.INFO,
                        "CnInvUplDbtP1 rebuild unloadKey={0} baseUpl={1} inserted={2}",
                        new Object[]{unloadKey, baseUpl, inserted});
                return inserted;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось пересобрать CnInvUplDbtP1 unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public SudzDbtUplDbtValueLoadApplyResult applyDbtUplDbtValueLoadTail(int unloadKey, int yrKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        if (yrKey <= 0) {
            throw new IllegalArgumentException("yrKey должен быть положительным: " + yrKey);
        }
        SudzDbtUplDbtValueLoadSnapshot before = findDbtUplDbtValueLoadSnapshot(unloadKey, yrKey);
        int insertedValues = 0;
        if (before.tailReady() > 0) {
            insertedValues = applyDbtValueLoadTail(unloadKey, yrKey);
        }
        log.log(Level.INFO,
                "applyDbtUplDbtValueLoadTail unloadKey={0} values={1} tailAmb={2}",
                new Object[]{unloadKey, insertedValues, before.tailAmbiguous()});
        return new SudzDbtUplDbtValueLoadApplyResult(
                insertedValues, before.tailAmbiguous(), 0);
    }

    /**
     * INSERT {@code DbtValue} для tail-слотов (мост + Tbl, без Value на curr).
     * A1.1b: {@code tailCand} + {@code rnPick=1} — не более одного слота на
     * {@code (iKey, ttl)} в одном INSERT (batch-safe с триггером P1).
     *
     * @param unloadKey {@code upl_key}
     * @return число INSERT
     */
    private int applyDbtValueLoadTail(int unloadKey, int yrKey) {
        Optional<Integer> baseOpt = findBaseUplForCurr(unloadKey, yrKey);
        int baseUpl = baseOpt.orElse(unloadKey);
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        String bridge = q("invDbtDbtVar");
        String invDbtVar = q("invDbtVar");
        String tbl = q("CnInvDbtUplTbl");
        String ctes = sqlDbtValueLoadCoreCtes(
                dbtValue, invDbt, invDbtDbt, bridge, invDbtVar, tbl, unloadKey, baseUpl);
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        String tsLit = "'" + now.toLocalDateTime() + "'";
        String insertSql = ctes
                + ", "
                + "tailCand AS ( "
                + "  SELECT tr.slotKey, b.iddvInvDbtVar, d.idInv AS iKey, "
                + "         COALESCE(t.cidutDebt, CAST(0 AS money)) AS cidutDebt, "
                + "         COALESCE(t.cidutDebtOverdue, CAST(0 AS money)) AS cidutDebtOverdue, "
                + "         CAST(t.cidutFormtnDate AS date) AS cidutFormtnDate, "
                + "         CAST(t.cidutMatrtyDate AS date) AS cidutMatrtyDate, "
                + "         COALESCE(NULLIF(LTRIM(RTRIM(t.cidutDoc)), N''), t.cidutCnInv) AS cidutDoc, "
                + "         ROW_NUMBER() OVER ( "
                + "           PARTITION BY d.idInv, "
                + "                        CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4)) "
                + "           ORDER BY tr.slotKey ASC "
                + "         ) AS rnPick "
                + "  FROM tailReady AS tr "
                + "  INNER JOIN " + bridge + " AS b ON b.iddvInvDbt = tr.slotKey "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = tr.slotKey "
                + "  CROSS APPLY ( "
                + "    SELECT TOP 1 a.cidutDebt, a.cidutDebtOverdue, a.cidutFormtnDate,"
                + "           a.cidutMatrtyDate, a.cidutDoc, a.cidutCnInv "
                + "    FROM " + tbl + " AS a "
                + sqlTblSudzEiaJoin()
                + "    WHERE a.cidutUnloadKey = " + unloadKey + " AND e.iKey = d.idInv "
                + "    ORDER BY a.cidutKey "
                + "  ) AS t "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " dv "
                + "    WHERE dv.dvInvDbt = tr.slotKey AND dv.dvUpl = " + unloadKey
                + "  ) "
                + "    AND " + sqlNoSiblingValueAtUpl(
                        invDbt, dbtValue, unloadKey, "tr.slotKey", "d.idInv",
                        "CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4))")
                + ") "
                + "INSERT INTO " + dbtValue
                + " (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,"
                + "  dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry) "
                + "SELECT tc.slotKey, tc.iddvInvDbtVar, " + unloadKey + ","
                + " tc.cidutDebt, tc.cidutDebtOverdue,"
                + " tc.cidutFormtnDate, tc.cidutMatrtyDate,"
                + " tc.cidutDoc, CAST(" + tsLit + " AS datetime2) "
                + "FROM tailCand AS tc "
                + "WHERE tc.rnPick = 1";
        try (Connection connection = connectionFactory.createConnection()) {
            fillSudzEiaTemp(connection, unloadKey);
            try (Statement statement = connection.createStatement()) {
                return statement.executeUpdate(insertSql);
            }
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить tail dbtValueLoad unloadKey=" + unloadKey, exception);
        }
    }

    private static void dropDbtValueLoadTemps(Connection connection) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvTblCurr') IS NOT NULL DROP TABLE #dvTblCurr");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvDisappeared') IS NOT NULL DROP TABLE #dvDisappeared");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvP1Cand') IS NOT NULL DROP TABLE #dvP1Cand");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvP1None') IS NOT NULL DROP TABLE #dvP1None");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvBaseCtx') IS NOT NULL DROP TABLE #dvBaseCtx");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvTailReady') IS NOT NULL DROP TABLE #dvTailReady");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#dvTailAmb') IS NOT NULL DROP TABLE #dvTailAmb");
            statement.executeUpdate("IF OBJECT_ID('tempdb..#tblIKey') IS NOT NULL DROP TABLE #tblIKey");
        }
    }

    private Optional<Integer> findBaseUplOnConnection(Connection connection, int unloadKey, int yrKey)
            throws SQLException {
        String sql = "SELECT y.cn_inv_dbt_upl AS baseUpl "
                + "FROM " + q("yr") + " AS y "
                + "INNER JOIN " + q("yr_upl_p") + " AS yp "
                + "  ON yp.yr_upl_p_yr = y.yr_key AND yp.cn_inv_dbt_upl = ? "
                + "WHERE y.yr_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            statement.setInt(2, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(rs.getInt("baseUpl"));
            }
        }
    }

    private int countDbtValuesOnConnection(Connection connection, int unloadKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM " + q("DbtValue") + " WHERE dvUpl = ?")) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private int countDbtP1QueuedOnConnection(Connection connection, int unloadKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM " + q("CnInvUplDbtP1") + " WHERE cip1UnloadKey = ?")) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return 0;
            }
            throw exception;
        }
    }

    private int countDbtP1OpenOnConnection(Connection connection, int unloadKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM " + q("CnInvUplDbtP1")
                        + " WHERE cip1UnloadKey = ? AND cip1Status = N'open'")) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return 0;
            }
            throw exception;
        }
    }

    private void materializeDbtValueLoadWorksetOnConnection(
            Connection connection,
            int unloadKey,
            int baseUpl,
            String tbl,
            String dbtValue,
            String invDbt,
            String invDbtDbt,
            String bridge
    ) throws SQLException {
        String eiaJoin = sqlTblSudzEiaJoin();
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate(
                    "SELECT a.cidutKey, e.iKey, "
                            + "CAST(a.cidutDebt AS decimal(19,4)) AS debt, "
                            + "a.cidutCnName, a.cidutCnInv "
                            + "INTO #dvTblCurr "
                            + "FROM " + tbl + " AS a "
                            + eiaJoin
                            + " WHERE a.cidutUnloadKey = " + unloadKey + " AND e.iKey IS NOT NULL");
            String disappearedSql = sqlDbtValueLoadDisappearedCte(
                    dbtValue, invDbtDbt, invDbt, unloadKey, baseUpl)
                    + "SELECT slotKey, dbtKey, iKey, debt, overd INTO #dvDisappeared FROM disappeared";
            statement.executeUpdate(disappearedSql);
            statement.executeUpdate(
                    sqlDbtValueLoadTailOnlyCtes(dbtValue, invDbt, invDbtDbt, bridge, tbl, unloadKey)
                            + "SELECT slotKey, iKey INTO #dvTailReady FROM tailReady");
            statement.executeUpdate(
                    sqlDbtValueLoadTailOnlyCtes(dbtValue, invDbt, invDbtDbt, bridge, tbl, unloadKey)
                            + "SELECT slotKey INTO #dvTailAmb FROM tailAmbiguous");
            statement.executeUpdate(
                    "SELECT iKey, COUNT(DISTINCT cidutKey) AS rowCnt INTO #tblIKey "
                            + "FROM #dvTblCurr GROUP BY iKey");
            statement.executeUpdate(
                    "SELECT ms.dbtKey, ms.slotKey, ms.iKey AS baseIKey, ms.matchSum, ms.sumKind, "
                            + "       t.cidutKey, t.iKey AS candIKey, t.debt AS candDebt, "
                            + "       t.cidutCnName, t.cidutCnInv "
                            + "INTO #dvP1Cand "
                            + "FROM ( "
                            + "  SELECT dbtKey, slotKey, iKey, debt AS matchSum, "
                            + "         CAST(N'ttl' AS varchar(8)) AS sumKind "
                            + "  FROM #dvDisappeared "
                            + "  UNION ALL "
                            + "  SELECT dbtKey, slotKey, iKey, overd, CAST(N'overd' AS varchar(8)) "
                            + "  FROM #dvDisappeared "
                            + "  WHERE overd IS NOT NULL AND overd > CAST(0 AS decimal(19,4)) "
                            + ") AS ms "
                            + "INNER JOIN #dvTblCurr AS t "
                            + "  ON ABS(t.debt - ms.matchSum) <= CAST(0.01 AS decimal(19,4))");
            statement.executeUpdate(
                    "SELECT ms.dbtKey, ms.slotKey, ms.iKey AS baseIKey, ms.matchSum, ms.sumKind "
                            + "INTO #dvP1None "
                            + "FROM ( "
                            + "  SELECT dbtKey, slotKey, iKey, debt AS matchSum, "
                            + "         CAST(N'ttl' AS varchar(8)) AS sumKind "
                            + "  FROM #dvDisappeared "
                            + "  UNION ALL "
                            + "  SELECT dbtKey, slotKey, iKey, overd, CAST(N'overd' AS varchar(8)) "
                            + "  FROM #dvDisappeared "
                            + "  WHERE overd IS NOT NULL AND overd > CAST(0 AS decimal(19,4)) "
                            + ") AS ms "
                            + "WHERE NOT EXISTS ( "
                            + "  SELECT 1 FROM #dvP1Cand AS pc "
                            + "  WHERE pc.dbtKey = ms.dbtKey AND pc.sumKind = ms.sumKind "
                            + ")");
            String invDbtVar = q("invDbtVar");
            statement.executeUpdate(
                    "SELECT d.slotKey, d.dbtKey, d.iKey, "
                            + "       cn.cnnNum AS baseCnNum, inv.inNum AS baseInvNum "
                            + "INTO #dvBaseCtx "
                            + "FROM #dvDisappeared AS d "
                            + "INNER JOIN " + dbtValue + " AS dv "
                            + "  ON dv.dvInvDbt = d.slotKey AND dv.dvUpl = " + baseUpl
                            + " INNER JOIN " + invDbtVar + " AS v ON v.idvvKey = dv.dvInvDbtVar "
                            + "LEFT JOIN ags.cnNum AS cn ON cn.cnnKey = v.idvvCnNum "
                            + "LEFT JOIN ags.invNum AS inv ON inv.inKey = v.idvvInvNum");
        }
    }

    private SudzDbtUplDbtValueLoadSnapshot readDbtValueLoadSnapshotFromTempsOnConnection(
            Connection connection,
            int unloadKey,
            int baseUpl
    ) throws SQLException {
        int skipped = countDbtValuesOnConnection(connection, unloadKey);
        int p1Queued = countDbtP1QueuedOnConnection(connection, unloadKey);
        int p1Open = countDbtP1OpenOnConnection(connection, unloadKey);
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT "
                             + "(SELECT COUNT(*) FROM #dvTailReady) AS tailReady, "
                             + "(SELECT COUNT(*) FROM #dvTailAmb) AS tailAmbiguous, "
                             + "(SELECT COUNT(DISTINCT dbtKey) FROM #dvDisappeared) AS disappeared")) {
            rs.next();
            return new SudzDbtUplDbtValueLoadSnapshot(
                    baseUpl,
                    skipped,
                    rs.getInt("tailReady"),
                    rs.getInt("tailAmbiguous"),
                    rs.getInt("disappeared"),
                    p1Queued,
                    p1Open);
        }
    }

    private int rebuildDbtP1QueueOnConnection(
            Connection connection,
            int unloadKey,
            Integer fileKey,
            int baseUpl
    ) throws SQLException {
        String queue = q("CnInvUplDbtP1");
        Integer dbtFileSql = fileKey == null ? null : fileKey;
        String fileLit = dbtFileSql == null ? "NULL" : String.valueOf(dbtFileSql);
        String detailCand = "N'[queue.build] исчез Dbt=' + CAST(pc.dbtKey AS nvarchar(20)) "
                + "+ N' sum=' + CAST(pc.matchSum AS nvarchar(32)) "
                + "+ N' → iKey=' + CAST(pc.candIKey AS nvarchar(20))";
        String detailNone = "N'[queue.build] исчез Dbt=' + CAST(n.dbtKey AS nvarchar(20)) "
                + "+ N' sum=' + CAST(n.matchSum AS nvarchar(32)) + N' — нет sum-match в Tbl'";
        String insertCand = "INSERT INTO " + queue + " ( "
                + "  cip1UnloadKey, cip1BaseUpl, cip1DbtFile, cip1DbtKey, cip1BaseSlotKey, cip1BaseIKey, "
                + "  cip1BaseCnNum, cip1BaseInvNum, cip1MatchSum, cip1SumKind, "
                + "  cip1CandCidut, cip1CandIKey, cip1CandCnNum, cip1CandInvNum, cip1CandDebt, "
                + "  cip1Reason, cip1ReasonDetail, cip1Status, cip1StatusAt "
                + ") "
                + "SELECT " + unloadKey + ", " + baseUpl + ", " + fileLit + ", "
                + "       pc.dbtKey, pc.slotKey, pc.baseIKey, "
                + "       bc.baseCnNum, bc.baseInvNum, pc.matchSum, pc.sumKind, "
                + "       pc.cidutKey, pc.candIKey, pc.cidutCnName, pc.cidutCnInv, pc.candDebt, "
                + "       CASE WHEN pg.candCnt = 1 THEN N'single' ELSE N'multi' END, "
                + "       " + detailCand + ", N'open', GETDATE() "
                + "FROM #dvP1Cand AS pc "
                + "INNER JOIN ( "
                + "  SELECT dbtKey, sumKind, COUNT(DISTINCT cidutKey) AS candCnt "
                + "  FROM #dvP1Cand GROUP BY dbtKey, sumKind "
                + ") AS pg ON pg.dbtKey = pc.dbtKey AND pg.sumKind = pc.sumKind "
                + "LEFT JOIN #dvBaseCtx AS bc ON bc.slotKey = pc.slotKey";
        String insertNone = "INSERT INTO " + queue + " ( "
                + "  cip1UnloadKey, cip1BaseUpl, cip1DbtFile, cip1DbtKey, cip1BaseSlotKey, cip1BaseIKey, "
                + "  cip1BaseCnNum, cip1BaseInvNum, cip1MatchSum, cip1SumKind, "
                + "  cip1Reason, cip1ReasonDetail, cip1Status, cip1StatusAt "
                + ") "
                + "SELECT " + unloadKey + ", " + baseUpl + ", " + fileLit + ", "
                + "       n.dbtKey, n.slotKey, n.baseIKey, "
                + "       bc.baseCnNum, bc.baseInvNum, n.matchSum, n.sumKind, "
                + "       N'none', " + detailNone + ", N'open', GETDATE() "
                + "FROM #dvP1None AS n "
                + "LEFT JOIN #dvBaseCtx AS bc ON bc.slotKey = n.slotKey";
        deleteDbtP1OnConnection(connection, unloadKey);
        int inserted = 0;
        try (Statement statement = connection.createStatement()) {
            inserted += statement.executeUpdate(insertCand);
            inserted += statement.executeUpdate(insertNone);
        }
        return inserted;
    }

    private int applyDbtValueLoadTailOnConnection(
            Connection connection,
            int unloadKey,
            String dbtValue,
            String invDbt,
            String bridge,
            String tbl,
            Timestamp now
    ) throws SQLException {
        String tsLit = "'" + now.toLocalDateTime() + "'";
        String insertSql = ""
                + "WITH tailCand AS ( "
                + "  SELECT tr.slotKey, b.iddvInvDbtVar, d.idInv AS iKey, "
                + "         COALESCE(t.cidutDebt, CAST(0 AS money)) AS cidutDebt, "
                + "         COALESCE(t.cidutDebtOverdue, CAST(0 AS money)) AS cidutDebtOverdue, "
                + "         CAST(t.cidutFormtnDate AS date) AS cidutFormtnDate, "
                + "         CAST(t.cidutMatrtyDate AS date) AS cidutMatrtyDate, "
                + "         COALESCE(NULLIF(LTRIM(RTRIM(t.cidutDoc)), N''), t.cidutCnInv) AS cidutDoc, "
                + "         ROW_NUMBER() OVER ( "
                + "           PARTITION BY d.idInv, "
                + "                        CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4)) "
                + "           ORDER BY tr.slotKey ASC "
                + "         ) AS rnPick "
                + "  FROM #dvTailReady AS tr "
                + "  INNER JOIN " + bridge + " AS b ON b.iddvInvDbt = tr.slotKey "
                + "  INNER JOIN " + invDbt + " AS d ON d.idKey = tr.slotKey "
                + "  CROSS APPLY ( "
                + "    SELECT TOP 1 a.cidutDebt, a.cidutDebtOverdue, a.cidutFormtnDate,"
                + "           a.cidutMatrtyDate, a.cidutDoc, a.cidutCnInv "
                + "    FROM " + tbl + " AS a "
                + sqlTblSudzEiaJoin()
                + "    WHERE a.cidutUnloadKey = " + unloadKey + " AND e.iKey = d.idInv "
                + "    ORDER BY a.cidutKey "
                + "  ) AS t "
                + "  WHERE NOT EXISTS ( "
                + "    SELECT 1 FROM " + dbtValue + " dv "
                + "    WHERE dv.dvInvDbt = tr.slotKey AND dv.dvUpl = " + unloadKey
                + "  ) "
                + "    AND " + sqlNoSiblingValueAtUpl(
                        invDbt, dbtValue, unloadKey, "tr.slotKey", "d.idInv",
                        "CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19,4))",
                        "#tblIKey")
                + ") "
                + "INSERT INTO " + dbtValue
                + " (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,"
                + "  dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry) "
                + "SELECT tc.slotKey, tc.iddvInvDbtVar, " + unloadKey + ","
                + " tc.cidutDebt, tc.cidutDebtOverdue,"
                + " tc.cidutFormtnDate, tc.cidutMatrtyDate,"
                + " tc.cidutDoc, CAST(" + tsLit + " AS datetime2) "
                + "FROM tailCand AS tc "
                + "WHERE tc.rnPick = 1";
        try (Statement statement = connection.createStatement()) {
            return statement.executeUpdate(insertSql);
        }
    }

    @Override
    public SudzDbtUplDbtValueLoadPhaseResult runDbtValueLoadPhase(
            int unloadKey,
            Integer fileKey,
            int yrKey,
            boolean flLoad
    ) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        if (yrKey <= 0) {
            throw new IllegalArgumentException("yrKey должен быть положительным: " + yrKey);
        }
        long t0 = System.nanoTime();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                dropDbtValueLoadTemps(connection);
                fillSudzEiaTemp(connection, unloadKey);
                Optional<Integer> baseOpt = findBaseUplOnConnection(connection, unloadKey, yrKey);
                if (baseOpt.isEmpty() || baseOpt.get().equals(unloadKey)) {
                    deleteDbtP1OnConnection(connection, unloadKey);
                    int skipped = countDbtValuesOnConnection(connection, unloadKey);
                    int p1Open = countDbtP1OpenOnConnection(connection, unloadKey);
                    SudzDbtUplDbtValueLoadSnapshot snapshot = new SudzDbtUplDbtValueLoadSnapshot(
                            baseOpt.orElse(null), skipped, 0, 0, 0, 0, p1Open);
                    connection.commit();
                    return new SudzDbtUplDbtValueLoadPhaseResult(snapshot, null);
                }
                int baseUpl = baseOpt.get();
                String dbtValue = q("DbtValue");
                String invDbt = q("invDbt");
                String invDbtDbt = q("invDbtDbt");
                String bridge = q("invDbtDbtVar");
                String tbl = q("CnInvDbtUplTbl");
                materializeDbtValueLoadWorksetOnConnection(
                        connection, unloadKey, baseUpl, tbl, dbtValue, invDbt, invDbtDbt, bridge);
                int tailReadyBefore;
                int tailAmbBefore;
                try (Statement statement = connection.createStatement();
                     ResultSet rs = statement.executeQuery(
                             "SELECT (SELECT COUNT(*) FROM #dvTailReady) AS tailReady, "
                                     + "(SELECT COUNT(*) FROM #dvTailAmb) AS tailAmb")) {
                    rs.next();
                    tailReadyBefore = rs.getInt("tailReady");
                    tailAmbBefore = rs.getInt("tailAmb");
                }
                int p1Queued = rebuildDbtP1QueueOnConnection(connection, unloadKey, fileKey, baseUpl);
                SudzDbtUplDbtValueLoadApplyResult applyResult = null;
                if (flLoad && tailReadyBefore > 0) {
                    Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                    int insertedValues = applyDbtValueLoadTailOnConnection(
                            connection, unloadKey, dbtValue, invDbt, bridge, tbl, now);
                    try (Statement statement = connection.createStatement()) {
                        statement.executeUpdate(
                                "DELETE tr FROM #dvTailReady AS tr "
                                        + "WHERE EXISTS ( "
                                        + "  SELECT 1 FROM " + dbtValue + " AS dv "
                                        + "  WHERE dv.dvInvDbt = tr.slotKey AND dv.dvUpl = " + unloadKey
                                        + ")");
                    }
                    applyResult = new SudzDbtUplDbtValueLoadApplyResult(
                            insertedValues, tailAmbBefore, p1Queued);
                }
                SudzDbtUplDbtValueLoadSnapshot snapshot =
                        readDbtValueLoadSnapshotFromTempsOnConnection(connection, unloadKey, baseUpl);
                connection.commit();
                long ms = (System.nanoTime() - t0) / 1_000_000L;
                log.log(Level.INFO,
                        "runDbtValueLoadPhase unloadKey={0} yrKey={1} flLoad={2} p1={3} tail={4} totalMs={5}",
                        new Object[]{unloadKey, yrKey, flLoad, p1Queued,
                                applyResult == null ? 0 : applyResult.insertedValues(), ms});
                return new SudzDbtUplDbtValueLoadPhaseResult(snapshot, applyResult);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выполнить dbtValueLoad phase unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public List<SudzCnInvUplDbtP1> findDbtP1ByUnload(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            return loadDbtP1ByUnload(connection, unloadKey);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать CnInvUplDbtP1 unloadKey=" + unloadKey, exception);
        }
    }

    private List<SudzCnInvUplDbtP1> loadDbtP1ByUnload(Connection connection, int unloadKey) throws SQLException {
        String sql = "SELECT cip1Key, cip1UnloadKey, cip1BaseUpl, cip1DbtFile, cip1DbtKey, cip1BaseSlotKey, "
                + "       cip1BaseIKey, cip1BaseCnNum, cip1BaseInvNum, cip1MatchSum, cip1SumKind, "
                + "       cip1CandCidut, cip1CandIKey, cip1CandCnNum, cip1CandInvNum, cip1CandDebt, "
                + "       cip1Reason, cip1ReasonDetail, cip1Status, cip1StatusAt, cip1LinkedSlotKey "
                + "FROM " + q("CnInvUplDbtP1")
                + " WHERE cip1UnloadKey = ? "
                + "ORDER BY cip1DbtKey, cip1SumKind, cip1CandCidut";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzCnInvUplDbtP1> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(mapDbtP1(rs));
                }
                return List.copyOf(result);
            }
        }
    }

    private static SudzCnInvUplDbtP1 mapDbtP1(ResultSet rs) throws SQLException {
        Timestamp statusAt = rs.getTimestamp("cip1StatusAt");
        return new SudzCnInvUplDbtP1(
                rs.getInt("cip1Key"),
                rs.getInt("cip1UnloadKey"),
                rs.getInt("cip1BaseUpl"),
                getInteger(rs, "cip1DbtFile"),
                rs.getInt("cip1DbtKey"),
                rs.getInt("cip1BaseSlotKey"),
                getInteger(rs, "cip1BaseIKey"),
                rs.getNString("cip1BaseCnNum"),
                rs.getNString("cip1BaseInvNum"),
                rs.getBigDecimal("cip1MatchSum"),
                rs.getString("cip1SumKind"),
                getInteger(rs, "cip1CandCidut"),
                getInteger(rs, "cip1CandIKey"),
                rs.getNString("cip1CandCnNum"),
                rs.getNString("cip1CandInvNum"),
                rs.getBigDecimal("cip1CandDebt"),
                rs.getString("cip1Reason"),
                rs.getNString("cip1ReasonDetail"),
                rs.getString("cip1Status"),
                toOffsetDateTime(statusAt),
                getInteger(rs, "cip1LinkedSlotKey")
        );
    }

    private int countDbtValuesOnUpl(int unloadKey) {
        String sql = "SELECT COUNT(*) FROM " + q("DbtValue") + " WHERE dvUpl = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            throw wrap("Не удалось посчитать DbtValue upl=" + unloadKey, exception);
        }
    }

    private int countDbtP1Queued(int unloadKey) {
        String sql = "SELECT COUNT(*) FROM " + q("CnInvUplDbtP1") + " WHERE cip1UnloadKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return 0;
            }
            throw wrap("Не удалось посчитать CnInvUplDbtP1 upl=" + unloadKey, exception);
        }
    }

    private int countDbtP1Open(int unloadKey) {
        String sql = "SELECT COUNT(*) FROM " + q("CnInvUplDbtP1")
                + " WHERE cip1UnloadKey = ? AND cip1Status = N'open'";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return 0;
            }
            throw wrap("Не удалось посчитать open CnInvUplDbtP1 upl=" + unloadKey, exception);
        }
    }

    private void deleteDbtP1ForUnload(int unloadKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            deleteDbtP1OnConnection(connection, unloadKey);
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return;
            }
            throw wrap("Не удалось очистить CnInvUplDbtP1 upl=" + unloadKey, exception);
        }
    }

    private void deleteDbtP1OnConnection(Connection connection, int unloadKey) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM " + q("CnInvUplDbtP1") + " WHERE cip1UnloadKey = ?")) {
            ps.setInt(1, unloadKey);
            ps.executeUpdate();
        } catch (SQLException exception) {
            if (isMissingTable(exception, "CnInvUplDbtP1")) {
                return;
            }
            throw exception;
        }
    }

    private static boolean isMissingTable(SQLException exception, String tableName) {
        String msg = exception.getMessage();
        return msg != null && msg.contains(tableName) && msg.contains("Invalid object name");
    }

    /**
     * C1 для одного слота: F1 reuse или новый {@code Dbt}; при sibling без F1 — исключение.
     *
     * @param connection открытое соединение (транзакция снаружи)
     * @param slotKey {@code invDbt.idKey}
     * @param iKey {@code iKey}
     * @param debt сумма Value
     * @param now метка времени
     * @throws SQLException при ошибке SQL
     */
    private void ensureInvDbtDbtBridgeForSlot(
            Connection connection,
            int slotKey,
            int iKey,
            BigDecimal debt,
            Timestamp now
    ) throws SQLException {
        String dbt = q("Dbt");
        String dbtValue = q("DbtValue");
        String invDbt = q("invDbt");
        String invDbtDbt = q("invDbtDbt");
        try (PreparedStatement exists = connection.prepareStatement(
                "SELECT 1 FROM " + invDbtDbt + " WHERE iddInvDbt = ?")) {
            exists.setInt(1, slotKey);
            try (ResultSet rs = exists.executeQuery()) {
                if (rs.next()) {
                    return;
                }
            }
        }
        if (debt == null) {
            throw new IllegalArgumentException("Нет суммы для привязки Dbt к слоту " + slotKey);
        }
        Integer reuseDbt = null;
        String f1Sql = ""
                + "SELECT DISTINCT idd.iddDbt AS dbtKey "
                + "FROM " + invDbt + " AS d2 "
                + "INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = d2.idKey "
                + "INNER JOIN " + dbtValue + " AS dv2 ON dv2.dvInvDbt = d2.idKey "
                + "WHERE d2.idInv = ? AND d2.idKey <> ? "
                + "  AND ABS(CAST(dv2.dvTtl AS decimal(19,4)) - ?) <= CAST(0.01 AS decimal(19,4))";
        try (PreparedStatement ps = connection.prepareStatement(f1Sql)) {
            ps.setInt(1, iKey);
            ps.setInt(2, slotKey);
            ps.setBigDecimal(3, debt);
            List<Integer> matches = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    matches.add(rs.getInt("dbtKey"));
                }
            }
            if (matches.size() == 1) {
                reuseDbt = matches.get(0);
            }
        }
        if (reuseDbt == null) {
            try (PreparedStatement sib = connection.prepareStatement(
                    "SELECT 1 FROM " + invDbt + " AS d2 "
                            + "INNER JOIN " + invDbtDbt + " AS idd ON idd.iddInvDbt = d2.idKey "
                            + "WHERE d2.idInv = ? AND d2.idKey <> ?")) {
                sib.setInt(1, iKey);
                sib.setInt(2, slotKey);
                try (ResultSet rs = sib.executeQuery()) {
                    if (rs.next()) {
                        throw new IllegalArgumentException(
                                "Неоднозначная привязка Dbt для слота " + slotKey
                                        + " (есть sibling без F1) — только лог/ручной разбор");
                    }
                }
            }
        }
        int dbtKey;
        if (reuseDbt != null) {
            dbtKey = reuseDbt;
        } else {
            try (PreparedStatement ins = connection.prepareStatement(
                    "INSERT INTO " + dbt + " (dbtTimeOfEntry, dbtNote) VALUES (?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ins.setTimestamp(1, now);
                ins.setString(2, "C1-screen-slot=" + slotKey);
                ins.executeUpdate();
                dbtKey = readGeneratedKey(ins, "Не удалось получить dbtKey");
            }
        }
        try (PreparedStatement br = connection.prepareStatement(
                "INSERT INTO " + invDbtDbt
                        + " (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry) VALUES (?, ?, ?, ?)")) {
            br.setInt(1, iKey);
            br.setInt(2, dbtKey);
            br.setInt(3, slotKey);
            br.setTimestamp(4, now);
            br.executeUpdate();
        }
    }

    @Override
    public List<SudzCnInvUplInvDbtDouble> findInvDbtDoublesByUnload(int unloadKey) {
        if (unloadKey <= 0) {
            throw new IllegalArgumentException("unloadKey должен быть положительным: " + unloadKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            return loadInvDbtDoublesByUnload(connection, unloadKey);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать CnInvUplInvDbtDouble unloadKey=" + unloadKey, exception);
        }
    }

    /**
     * Очередь двоящих долгов СФ в рамках открытого соединения.
     *
     * @param connection соединение
     * @param unloadKey {@code upl_key}
     * @return строки
     * @throws SQLException при ошибке JDBC
     */
    private List<SudzCnInvUplInvDbtDouble> loadInvDbtDoublesByUnload(
            Connection connection,
            int unloadKey
    ) throws SQLException {
        String sql = "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey, "
                + "ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason, "
                + "ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey "
                + "FROM " + q("CnInvUplInvDbtDouble")
                + " WHERE ciudUnloadKey = ?"
                + " ORDER BY ciudStatus, CASE WHEN ciudIKey IS NULL THEN 1 ELSE 0 END, ciudIKey, ciudKey";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            List<SudzCnInvUplInvDbtDouble> result = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(mapInvDbtDouble(rs));
                }
            }
            return List.copyOf(result);
        }
    }

    @Override
    public Optional<SudzSfDoubleExcelCandidate> findInvDbtDoubleExcelCandidate(int ciudKey) {
        if (ciudKey <= 0) {
            throw new IllegalArgumentException("ciudKey должен быть положительным: " + ciudKey);
        }
        String sql = ""
                + "SELECT t.cidutKey, t.FindDbtNum, t.cidutAccount, acc.account_num AS cidutAccntNum,"
                + " t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN, t.cidutCnName, t.cidutCnDate,"
                + " t.cidutCnInv, t.cidutCnInvName, t.cidutFormtnDate, t.cidutMatrtyDate,"
                + " t.cidutDebt, t.cidutDebtOverdue, t.cidutDoc, t.cidutLink,"
                + " t.cidutSheet, t.cidutSheetNum, t.cidutUnloadKey"
                + " FROM " + q("CnInvUplInvDbtDouble") + " AS q"
                + " INNER JOIN " + q("CnInvDbtUplTbl") + " AS t ON t.cidutKey = q.ciudCidut"
                + " LEFT JOIN ags.accnt AS acc ON acc.account_key = t.cidutAccount"
                + " WHERE q.ciudKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciudKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapExcelCandidate(rs));
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать Excel-кандидата ciudKey=" + ciudKey, exception);
        }
    }

    @Override
    public List<SudzInvDbtSlot> findInvDbtSlotsByInv(int iKey) {
        if (iKey <= 0) {
            throw new IllegalArgumentException("iKey должен быть положительным: " + iKey);
        }
        String sql = "SELECT idKey, idInv, idNum, idNote FROM " + q("invDbt")
                + " WHERE idInv = ? ORDER BY idNum, idKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iKey);
            List<SudzInvDbtSlot> result = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(new SudzInvDbtSlot(
                            rs.getInt("idKey"),
                            rs.getInt("idInv"),
                            rs.getInt("idNum"),
                            rs.getNString("idNote")
                    ));
                }
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать invDbt для iKey=" + iKey, exception);
        }
    }

    @Override
    public SudzCnInvUplInvDbtDouble createInvDbtFromDouble(int ciudKey) {
        return resolveInvDbtDouble(ciudKey, null);
    }

    @Override
    public SudzCnInvUplInvDbtDouble linkInvDbtDouble(int ciudKey, int idKey) {
        if (idKey <= 0) {
            throw new IllegalArgumentException("idKey должен быть положительным: " + idKey);
        }
        return resolveInvDbtDouble(ciudKey, idKey);
    }

    @Override
    public SudzInvDbtVarCandidates findInvDbtVarCandidates(int ciudKey) {
        if (ciudKey <= 0) {
            throw new IllegalArgumentException("ciudKey должен быть положительным: " + ciudKey);
        }
        String queue = q("CnInvUplInvDbtDouble");
        String tbl = q("CnInvDbtUplTbl");
        String sidesSql = ""
                + "SELECT DISTINCT c.cn_key, o.cn_s_org_key, "
                + "       CAST(o.csoCnDate AS date) AS csoCnDate "
                + "FROM " + queue + " AS q "
                + "INNER JOIN " + tbl + " AS t ON t.cidutKey = q.ciudCidut "
                + "INNER JOIN ags.cnNum AS num "
                + "  ON num.cnnNumNull = CASE "
                + "       WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' "
                + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END "
                + "INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn "
                + "INNER JOIN ags.cn_s AS s ON s.cn_key = c.cn_key AND s.cn_s_type = 2 "
                + "INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s "
                + "INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl "
                + "INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key "
                + "WHERE q.ciudKey = ? "
                + "  AND t.cidutCntrPrtNum = i.org_id_value_l "
                + "  AND CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "           ELSE CAST(t.cidutCnDate AS date) END "
                + "    = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                + "           ELSE CAST(o.csoCnDate AS date) END";
        String cnNumSql = ""
                + "SELECT n.cnnKey, n.cnnCn, n.cnnNumNull "
                + "FROM ags.cnNum AS n "
                + "WHERE n.cnnType = 1 AND n.cnnCn IN ("
                + "  SELECT DISTINCT c.cn_key "
                + "  FROM " + queue + " AS q "
                + "  INNER JOIN " + tbl + " AS t ON t.cidutKey = q.ciudCidut "
                + "  INNER JOIN ags.cnNum AS num "
                + "    ON num.cnnNumNull = CASE "
                + "         WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' "
                + "         THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END "
                + "  INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn "
                + "  INNER JOIN ags.cn_s AS s ON s.cn_key = c.cn_key AND s.cn_s_type = 2 "
                + "  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s "
                + "  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl "
                + "  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key "
                + "  WHERE q.ciudKey = ? "
                + "    AND t.cidutCntrPrtNum = i.org_id_value_l "
                + "    AND CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) "
                + "             ELSE CAST(t.cidutCnDate AS date) END "
                + "      = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) "
                + "             ELSE CAST(o.csoCnDate AS date) END"
                + ") "
                + "ORDER BY n.cnnCn, n.cnnKey";
        String invNumSql = ""
                + "SELECT n.inKey, n.inInv, n.inNumNull "
                + "FROM ags.invNum AS n "
                + "INNER JOIN " + queue + " AS q ON q.ciudIKey = n.inInv "
                + "INNER JOIN " + tbl + " AS t ON t.cidutKey = q.ciudCidut "
                + "WHERE q.ciudKey = ? "
                + "  AND n.inNumNull = CASE "
                + "       WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N'' "
                + "       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END "
                + "ORDER BY n.inKey";
        String headSql = ""
                + "SELECT q.ciudKey, q.ciudIKey, t.cidutAccount "
                + "FROM " + queue + " AS q "
                + "INNER JOIN " + tbl + " AS t ON t.cidutKey = q.ciudCidut "
                + "WHERE q.ciudKey = ?";
        try (Connection connection = connectionFactory.createConnection()) {
            Integer iKey;
            Integer accountKey;
            try (PreparedStatement ps = connection.prepareStatement(headSql)) {
                ps.setInt(1, ciudKey);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Строка очереди не найдена: " + ciudKey);
                    }
                    iKey = getInteger(rs, "ciudIKey");
                    accountKey = getInteger(rs, "cidutAccount");
                }
            }
            List<SudzInvDbtVarSideCandidate> sides = new ArrayList<>();
            try (PreparedStatement ps = connection.prepareStatement(sidesSql)) {
                ps.setInt(1, ciudKey);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        sides.add(new SudzInvDbtVarSideCandidate(
                                rs.getInt("cn_key"),
                                rs.getInt("cn_s_org_key"),
                                getLocalDate(rs, "csoCnDate")
                        ));
                    }
                }
            }
            List<SudzInvDbtVarCnNumCandidate> cnNums = new ArrayList<>();
            try (PreparedStatement ps = connection.prepareStatement(cnNumSql)) {
                ps.setInt(1, ciudKey);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        cnNums.add(new SudzInvDbtVarCnNumCandidate(
                                rs.getInt("cnnKey"),
                                rs.getInt("cnnCn"),
                                rs.getNString("cnnNumNull")
                        ));
                    }
                }
            }
            List<SudzInvDbtVarInvNumCandidate> invNums = new ArrayList<>();
            try (PreparedStatement ps = connection.prepareStatement(invNumSql)) {
                ps.setInt(1, ciudKey);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        invNums.add(new SudzInvDbtVarInvNumCandidate(
                                rs.getInt("inKey"),
                                rs.getInt("inInv"),
                                rs.getNString("inNumNull")
                        ));
                    }
                }
            }
            return new SudzInvDbtVarCandidates(
                    ciudKey,
                    iKey,
                    accountKey,
                    List.copyOf(sides),
                    List.copyOf(cnNums),
                    List.copyOf(invNums)
            );
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось выбрать кандидатов invDbtVar ciudKey=" + ciudKey, exception);
        }
    }

    @Override
    public SudzCnInvUplInvDbtDouble ensureInvDbtVarForDouble(
            int ciudKey,
            int idvvCnNum,
            int idvvInvNum,
            int idvvAccnt,
            int idvvCnSOrg
    ) {
        if (ciudKey <= 0 || idvvCnNum <= 0 || idvvInvNum <= 0 || idvvAccnt <= 0 || idvvCnSOrg <= 0) {
            throw new IllegalArgumentException(
                    "ciudKey и FK invDbtVar должны быть положительными");
        }
        SudzInvDbtVarCandidates candidates = findInvDbtVarCandidates(ciudKey);
        if (candidates.iKey() == null || candidates.iKey() <= 0) {
            throw new IllegalArgumentException("У строки очереди нет iKey");
        }
        if (candidates.accountKey() == null || candidates.accountKey() != idvvAccnt) {
            throw new IllegalArgumentException(
                    "idvvAccnt должен совпадать с cidutAccount Excel ("
                            + candidates.accountKey() + ")");
        }
        boolean sideOk = candidates.sides().stream()
                .anyMatch(s -> s.cnSOrgKey() == idvvCnSOrg);
        if (!sideOk) {
            throw new IllegalArgumentException(
                    "idvvCn_s_org не входит в ExistList для строки очереди: " + idvvCnSOrg);
        }
        SudzInvDbtVarCnNumCandidate cnPick = candidates.cnNums().stream()
                .filter(c -> c.cnnKey() == idvvCnNum)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "idvvCnNum не среди кандидатов type=1: " + idvvCnNum));
        boolean sideMatchesCn = candidates.sides().stream()
                .anyMatch(s -> s.cnKey() == cnPick.cnKey() && s.cnSOrgKey() == idvvCnSOrg);
        if (!sideMatchesCn) {
            throw new IllegalArgumentException(
                    "cnNum " + idvvCnNum + " не согласован со стороной " + idvvCnSOrg);
        }
        boolean invOk = candidates.invNums().stream()
                .anyMatch(n -> n.inKey() == idvvInvNum && n.inInv() == candidates.iKey());
        if (!invOk) {
            throw new IllegalArgumentException(
                    "idvvInvNum не среди кандидатов для iKey=" + candidates.iKey());
        }

        String queue = q("CnInvUplInvDbtDouble");
        String invDbtVar = q("invDbtVar");
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzCnInvUplInvDbtDouble row;
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey,"
                                + " ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason,"
                                + " ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey"
                                + " FROM " + queue + " WHERE ciudKey = ?")) {
                    ps.setInt(1, ciudKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Строка очереди не найдена: " + ciudKey);
                        }
                        row = mapInvDbtDouble(rs);
                    }
                }
                if (!"open".equals(row.ciudStatus())) {
                    throw new IllegalArgumentException(
                            "Выбор контекста возможен только со статусом open, сейчас: " + row.ciudStatus());
                }
                Integer idvvKey = null;
                try (PreparedStatement find = connection.prepareStatement(
                        "SELECT idvvKey FROM " + invDbtVar
                                + " WHERE idvvCnNum = ? AND idvvInvNum = ? "
                                + "   AND idvvAccnt = ? AND idvvCn_s_org = ?")) {
                    find.setInt(1, idvvCnNum);
                    find.setInt(2, idvvInvNum);
                    find.setInt(3, idvvAccnt);
                    find.setInt(4, idvvCnSOrg);
                    try (ResultSet rs = find.executeQuery()) {
                        if (rs.next()) {
                            idvvKey = rs.getInt(1);
                        }
                    }
                }
                if (idvvKey == null) {
                    try (PreparedStatement ins = connection.prepareStatement(
                            "INSERT INTO " + invDbtVar
                                    + " (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry) "
                                    + "VALUES (?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        ins.setInt(1, idvvCnNum);
                        ins.setInt(2, idvvInvNum);
                        ins.setInt(3, idvvAccnt);
                        ins.setInt(4, idvvCnSOrg);
                        ins.setTimestamp(5, now);
                        ins.executeUpdate();
                        idvvKey = readGeneratedKey(ins, "Не удалось получить idvvKey");
                    }
                }
                try (PreparedStatement upd = connection.prepareStatement(
                        "UPDATE " + queue
                                + " SET ciudIdvvKey = ?, ciudStatusAt = ?"
                                + " WHERE ciudKey = ?")) {
                    upd.setInt(1, idvvKey);
                    upd.setTimestamp(2, now);
                    upd.setInt(3, ciudKey);
                    upd.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO,
                        "ensureInvDbtVarForDouble ciudKey={0} idvvKey={1} cnn={2} invNum={3}",
                        new Object[]{ciudKey, idvvKey, idvvCnNum, idvvInvNum});
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey,"
                                + " ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason,"
                                + " ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey"
                                + " FROM " + queue + " WHERE ciudKey = ?")) {
                    ps.setInt(1, ciudKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        return mapInvDbtDouble(rs);
                    }
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать invDbtVar для ciudKey=" + ciudKey, exception);
        }
    }

    @Override
    public SudzInvDbtDoubleAdvice findInvDbtDoubleAdvice(int ciudKey, BigDecimal epsilon) {
        if (ciudKey <= 0) {
            throw new IllegalArgumentException("ciudKey должен быть положительным: " + ciudKey);
        }
        SudzCnInvUplInvDbtDouble row = loadInvDbtDoubleByKey(ciudKey);
        SudzSfDoubleExcelCandidate excel = findInvDbtDoubleExcelCandidate(ciudKey).orElse(null);
        Integer iKey = row.ciudIKey();
        if (iKey == null || iKey <= 0) {
            return new SudzInvDbtDoubleAdvice(
                    "[advisor]\ncheck=na: нет iKey на строке очереди",
                    "none",
                    "manual",
                    null,
                    row.ciudIdvvKey());
        }
        List<SudzInvDbtSlot> slots = findInvDbtSlotsByInv(iKey);
        Map<Integer, Integer> slotAccnts = new LinkedHashMap<>();
        Map<Integer, Integer> slotVars = new LinkedHashMap<>();
        loadSlotVarAccntMaps(slots, slotAccnts, slotVars);
        Optional<Integer> f1Slot = findF1UniqueSlot(iKey, row.ciudDebt(), epsilon);
        List<SudzSfDoubleNewSumMatch> newMatches = List.of();
        if (row.ciudDebt() != null) {
            java.util.Set<Integer> slotIds = new java.util.LinkedHashSet<>();
            for (SudzInvDbtSlot s : slots) {
                slotIds.add(s.idKey());
            }
            newMatches = findNewSumMatches(row.ciudDebt(), epsilon).stream()
                    .filter(m -> m.dvInvDbt() != null && slotIds.contains(m.dvInvDbt()))
                    .toList();
        }
        Map<Integer, List<SudzInvDbtTimelinePoint>> timelines = new LinkedHashMap<>();
        for (SudzInvDbtSlot slot : slots) {
            timelines.put(slot.idKey(), loadTimelinePoints(slot.idKey()));
        }
        LocalDate excelStatusDate = loadUplStatusOnDate(row.ciudUnloadKey());
        return InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                slotAccnts,
                slotVars,
                f1Slot,
                newMatches,
                timelines,
                excelStatusDate,
                epsilon);
    }

    @Override
    public SudzInvDbtSlotTimeline findInvDbtSlotTimeline(int iKey, int idKey, int ciudKey) {
        if (iKey <= 0 || idKey <= 0 || ciudKey <= 0) {
            throw new IllegalArgumentException("iKey, idKey и ciudKey должны быть положительными");
        }
        SudzCnInvUplInvDbtDouble row = loadInvDbtDoubleByKey(ciudKey);
        if (row.ciudIKey() == null || row.ciudIKey() != iKey) {
            throw new IllegalArgumentException("ciudKey не относится к iKey=" + iKey);
        }
        SudzInvDbtSlot slot = findInvDbtSlotsByInv(iKey).stream()
                .filter(s -> s.idKey() == idKey)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Слот не найден: " + idKey));
        Map<Integer, Integer> accnts = new LinkedHashMap<>();
        Map<Integer, Integer> vars = new LinkedHashMap<>();
        loadSlotVarAccntMaps(List.of(slot), accnts, vars);
        String ciaName = parseCiaNameFromNote(slot.idNote());
        List<SudzInvDbtTimelinePoint> points = loadTimelinePoints(idKey);
        LocalDate excelStatusDate = loadUplStatusOnDate(row.ciudUnloadKey());
        return new SudzInvDbtSlotTimeline(
                slot.idKey(),
                slot.idNum(),
                ciaName,
                vars.get(idKey),
                accnts.get(idKey),
                row.ciudDebt(),
                excelStatusDate,
                points);
    }

    /**
     * Загружает строку очереди двоящих по ключу.
     *
     * @param ciudKey ключ
     * @return строка
     */
    private SudzCnInvUplInvDbtDouble loadInvDbtDoubleByKey(int ciudKey) {
        String sql = "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey, "
                + "ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason, "
                + "ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey "
                + "FROM " + q("CnInvUplInvDbtDouble") + " WHERE ciudKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciudKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Строка очереди не найдена: " + ciudKey);
                }
                return mapInvDbtDouble(rs);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать очередь ciudKey=" + ciudKey, exception);
        }
    }

    /**
     * Дата среза выгрузки ({@code uplStatusOnDate}).
     *
     * @param uplKey ключ выгрузки
     * @return дата или null
     */
    private LocalDate loadUplStatusOnDate(int uplKey) {
        String upl = q("cn_inv_dbt_upl");
        String sql = "SELECT uplStatusOnDate FROM " + upl + " WHERE upl_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return getLocalDate(rs, "uplStatusOnDate");
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать uplStatusOnDate upl=" + uplKey, exception);
        }
    }

    /**
     * Точки {@code DbtValue} слота по времени.
     *
     * @param idKey слот invDbt
     * @return упорядоченный список
     */
    private List<SudzInvDbtTimelinePoint> loadTimelinePoints(int idKey) {
        String dv = q("DbtValue");
        String upl = q("cn_inv_dbt_upl");
        String sql = ""
                + "SELECT dv.dvUpl, CAST(u.uplStatusOnDate AS date) AS statusDate,"
                + " dv.dvTtl, dv.dvOverd, dv.dvInvDbtVar"
                + " FROM " + dv + " AS dv"
                + " LEFT JOIN " + upl + " AS u ON u.upl_key = dv.dvUpl"
                + " WHERE dv.dvInvDbt = ?"
                + " ORDER BY u.uplStatusOnDate, dv.dvUpl";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, idKey);
            List<SudzInvDbtTimelinePoint> result = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(new SudzInvDbtTimelinePoint(
                            getInteger(rs, "dvUpl"),
                            getLocalDate(rs, "statusDate"),
                            rs.getBigDecimal("dvTtl"),
                            rs.getBigDecimal("dvOverd"),
                            "dbtValue",
                            getInteger(rs, "dvInvDbtVar")
                    ));
                }
            }
            return List.copyOf(result);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать timeline idKey=" + idKey, exception);
        }
    }

    /**
     * Primary var и accnt по слотам.
     *
     * @param slots слоты
     * @param accnts out: idKey → accnt
     * @param vars out: idKey → var
     */
    private void loadSlotVarAccntMaps(
            List<SudzInvDbtSlot> slots,
            Map<Integer, Integer> accnts,
            Map<Integer, Integer> vars
    ) {
        if (slots.isEmpty()) {
            return;
        }
        String bridge = q("invDbtDbtVar");
        String var = q("invDbtVar");
        StringBuilder in = new StringBuilder();
        for (int i = 0; i < slots.size(); i++) {
            if (i > 0) {
                in.append(',');
            }
            in.append('?');
        }
        String sql = ""
                + "SELECT b.iddvInvDbt AS idKey, b.iddvInvDbtVar AS varKey, v.idvvAccnt AS accnt"
                + " FROM " + bridge + " AS b"
                + " INNER JOIN " + var + " AS v ON v.idvvKey = b.iddvInvDbtVar"
                + " WHERE b.iddvInvDbt IN (" + in + ")"
                + " ORDER BY b.iddvInvDbt, b.iddvKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int p = 1;
            for (SudzInvDbtSlot slot : slots) {
                statement.setInt(p++, slot.idKey());
            }
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    int idKey = rs.getInt("idKey");
                    if (!vars.containsKey(idKey)) {
                        vars.put(idKey, rs.getInt("varKey"));
                        accnts.put(idKey, rs.getInt("accnt"));
                    }
                }
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать var/accnt слотов", exception);
        }
    }

    /**
     * F1: единственный слот на iKey с историей DbtValue = debt.
     *
     * @param iKey СФ
     * @param debt сумма
     * @param epsilon допуск
     * @return idKey слота
     */
    private Optional<Integer> findF1UniqueSlot(int iKey, BigDecimal debt, BigDecimal epsilon) {
        if (debt == null) {
            return Optional.empty();
        }
        String invDbt = q("invDbt");
        String dbtValue = q("DbtValue");
        String sql = ""
                + "SELECT d.idKey"
                + " FROM " + invDbt + " AS d"
                + " WHERE d.idInv = ?"
                + "   AND EXISTS ("
                + "     SELECT 1 FROM " + dbtValue + " AS dv"
                + "     WHERE dv.dvInvDbt = d.idKey"
                + "       AND ABS(CAST(dv.dvTtl AS decimal(19,4)) - ?) <= ?"
                + "   )";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iKey);
            statement.setBigDecimal(2, debt);
            statement.setBigDecimal(3, epsilon);
            List<Integer> matches = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    matches.add(rs.getInt("idKey"));
                }
            }
            if (matches.size() == 1) {
                return Optional.of(matches.get(0));
            }
            return Optional.empty();
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось проверить F1 iKey=" + iKey, exception);
        }
    }

    /**
     * Извлекает ciaName из {@code idNote} ({@code ciaName=1}).
     *
     * @param idNote note слота
     * @return ciaName или null
     */
    private static String parseCiaNameFromNote(String idNote) {
        if (idNote == null || idNote.isBlank()) {
            return null;
        }
        String prefix = "ciaName=";
        int idx = idNote.indexOf(prefix);
        if (idx < 0) {
            return null;
        }
        return idNote.substring(idx + prefix.length()).trim();
    }

    /**
     * Create ({@code idKey==null}) или link слота + мост + {@code DbtValue}; строка очереди → {@code created}.
     *
     * @param ciudKey ключ очереди
     * @param linkIdKey существующий слот или null
     * @return обновлённая строка очереди
     */
    private SudzCnInvUplInvDbtDouble resolveInvDbtDouble(int ciudKey, Integer linkIdKey) {
        if (ciudKey <= 0) {
            throw new IllegalArgumentException("ciudKey должен быть положительным: " + ciudKey);
        }
        String queue = q("CnInvUplInvDbtDouble");
        String invDbt = q("invDbt");
        String bridge = q("invDbtDbtVar");
        String dbtValue = q("DbtValue");
        String tbl = q("CnInvDbtUplTbl");
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzCnInvUplInvDbtDouble row;
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey,"
                                + " ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason,"
                                + " ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey"
                                + " FROM " + queue + " WHERE ciudKey = ?")) {
                    ps.setInt(1, ciudKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Строка очереди не найдена: " + ciudKey);
                        }
                        row = mapInvDbtDouble(rs);
                    }
                }
                if (!"open".equals(row.ciudStatus())) {
                    throw new IllegalArgumentException(
                            "Разбор возможен только со статусом open, сейчас: " + row.ciudStatus());
                }
                if (row.ciudIKey() == null || row.ciudIKey() <= 0) {
                    throw new IllegalArgumentException("У строки очереди нет iKey");
                }
                if (row.ciudIdvvKey() == null || row.ciudIdvvKey() <= 0) {
                    throw new IllegalArgumentException(
                            "Нет invDbtVar (ciudIdvvKey): сначала «Выбрать контекст» на экране");
                }
                int iKey = row.ciudIKey();
                int idvvKey = row.ciudIdvvKey();
                int uplKey = row.ciudUnloadKey();
                int slotKey;
                if (linkIdKey == null) {
                    int nextNum = 1;
                    try (PreparedStatement mx = connection.prepareStatement(
                            "SELECT ISNULL(MAX(idNum), 0) + 1 FROM " + invDbt + " WHERE idInv = ?")) {
                        mx.setInt(1, iKey);
                        try (ResultSet rs = mx.executeQuery()) {
                            rs.next();
                            nextNum = rs.getInt(1);
                        }
                    }
                    try (PreparedStatement ins = connection.prepareStatement(
                            "INSERT INTO " + invDbt + " (idInv, idNum, idTimeOfEntry) VALUES (?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS)) {
                        ins.setInt(1, iKey);
                        ins.setInt(2, nextNum);
                        ins.setTimestamp(3, now);
                        ins.executeUpdate();
                        slotKey = readGeneratedKey(ins, "Не удалось получить idKey invDbt");
                    }
                } else {
                    try (PreparedStatement chk = connection.prepareStatement(
                            "SELECT idInv FROM " + invDbt + " WHERE idKey = ?")) {
                        chk.setInt(1, linkIdKey);
                        try (ResultSet rs = chk.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalArgumentException("Слот invDbt не найден: " + linkIdKey);
                            }
                            if (rs.getInt("idInv") != iKey) {
                                throw new IllegalArgumentException(
                                        "Слот " + linkIdKey + " принадлежит другой СФ (iKey)");
                            }
                        }
                    }
                    slotKey = linkIdKey;
                }
                try (PreparedStatement chkBr = connection.prepareStatement(
                        "SELECT 1 FROM " + bridge + " WHERE iddvInvDbt = ? AND iddvInvDbtVar = ?")) {
                    chkBr.setInt(1, slotKey);
                    chkBr.setInt(2, idvvKey);
                    boolean hasBridge;
                    try (ResultSet rs = chkBr.executeQuery()) {
                        hasBridge = rs.next();
                    }
                    if (!hasBridge) {
                        try (PreparedStatement br = connection.prepareStatement(
                                "INSERT INTO " + bridge
                                        + " (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry) VALUES (?, ?, ?)")) {
                            br.setInt(1, slotKey);
                            br.setInt(2, idvvKey);
                            br.setTimestamp(3, now);
                            br.executeUpdate();
                        }
                    }
                }
                try (PreparedStatement exists = connection.prepareStatement(
                        "SELECT 1 FROM " + dbtValue + " WHERE dvInvDbt = ? AND dvUpl = ?")) {
                    exists.setInt(1, slotKey);
                    exists.setInt(2, uplKey);
                    try (ResultSet rs = exists.executeQuery()) {
                        if (rs.next()) {
                            throw new IllegalArgumentException(
                                    "DbtValue для слота " + slotKey + " и upl " + uplKey
                                            + " уже есть — выберите другой слот (Create)");
                        }
                    }
                }
                try (PreparedStatement ins = connection.prepareStatement(
                        "INSERT INTO " + dbtValue
                                + " (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,"
                                + "  dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry) "
                                + "SELECT ?, ?, ?, "
                                + " COALESCE(t.cidutDebt, CAST(0 AS money)),"
                                + " COALESCE(t.cidutDebtOverdue, CAST(0 AS money)),"
                                + " CAST(t.cidutFormtnDate AS date), CAST(t.cidutMatrtyDate AS date),"
                                + " COALESCE(NULLIF(LTRIM(RTRIM(t.cidutDoc)), N''), t.cidutCnInv), ?"
                                + " FROM " + tbl + " AS t WHERE t.cidutKey = ?")) {
                    ins.setInt(1, slotKey);
                    ins.setInt(2, idvvKey);
                    ins.setInt(3, uplKey);
                    ins.setTimestamp(4, now);
                    ins.setInt(5, row.ciudCidut());
                    int n = ins.executeUpdate();
                    if (n != 1) {
                        throw new IllegalStateException("Не найдена строка Tbl cidut=" + row.ciudCidut());
                    }
                }
                BigDecimal debt = row.ciudDebt();
                ensureInvDbtDbtBridgeForSlot(connection, slotKey, iKey, debt, now);
                try (PreparedStatement upd = connection.prepareStatement(
                        "UPDATE " + queue
                                + " SET ciudStatus = 'created', ciudStatusAt = ?, ciudCreatedIdKey = ?"
                                + " WHERE ciudKey = ?")) {
                    upd.setTimestamp(1, now);
                    upd.setInt(2, slotKey);
                    upd.setInt(3, ciudKey);
                    upd.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO,
                        "resolveInvDbtDouble ciudKey={0} slot={1} link={2} upl={3} status=created",
                        new Object[]{ciudKey, slotKey, linkIdKey != null, uplKey});
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciudKey, ciudCidut, ciudDbtFile, ciudUnloadKey, ciudIKey, "
                                + "ciudCnNum, ciudInvNum, ciudDebt, ciudIdvvKey, ciudReason, "
                                + "ciudReasonDetail, ciudStatus, ciudStatusAt, ciudCreatedIdKey "
                                + "FROM " + queue + " WHERE ciudKey = ?")) {
                    ps.setInt(1, ciudKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException("Строка очереди не найдена после resolve: " + ciudKey);
                        }
                        return mapInvDbtDouble(rs);
                    }
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось разобрать двоящий долг ciudKey=" + ciudKey, exception);
        }
    }

    /**
     * Маппинг Excel-кандидата из ResultSet Tbl.
     *
     * @param rs курсор
     * @return кандидат
     * @throws SQLException JDBC
     */
    private static SudzSfDoubleExcelCandidate mapExcelCandidate(ResultSet rs) throws SQLException {
        return new SudzSfDoubleExcelCandidate(
                rs.getInt("cidutKey"),
                getInteger(rs, "FindDbtNum"),
                getInteger(rs, "cidutAccount"),
                getInteger(rs, "cidutAccntNum"),
                getInteger(rs, "cidutCntrPrtNum"),
                rs.getNString("cidutCntrPrtName"),
                rs.getNString("cidutCntrPrtITN"),
                rs.getNString("cidutCnName"),
                toLocalDate(rs.getTimestamp("cidutCnDate")),
                rs.getNString("cidutCnInv"),
                rs.getNString("cidutCnInvName"),
                toLocalDate(rs.getTimestamp("cidutFormtnDate")),
                toLocalDate(rs.getTimestamp("cidutMatrtyDate")),
                rs.getBigDecimal("cidutDebt"),
                rs.getBigDecimal("cidutDebtOverdue"),
                rs.getNString("cidutDoc"),
                rs.getNString("cidutLink"),
                getInteger(rs, "cidutSheet"),
                getInteger(rs, "cidutSheetNum"),
                getInteger(rs, "cidutUnloadKey")
        );
    }

    private static SudzDbtUplInvDbtVarEnsureRow mapInvDbtVarEnsureRow(ResultSet rs) throws SQLException {
        Date cnDateSql = rs.getDate("cidutCnDate");
        LocalDate cnDate = cnDateSql == null ? null : cnDateSql.toLocalDate();
        return new SudzDbtUplInvDbtVarEnsureRow(
                getInteger(rs, "cidutCntrPrtNum"),
                rs.getNString("cidutCntrPrtName"),
                rs.getNString("cidutCnName"),
                cnDate,
                rs.getNString("cidutCnInv"),
                rs.getInt("iKey"),
                rs.getInt("account_key"),
                rs.getInt("account_num"),
                getInteger(rs, "cnnKey"),
                getInteger(rs, "invNumKey"),
                rs.getInt("cn_s_org_key"),
                getInteger(rs, "idvvKey")
        );
    }

    private static SudzCnInvUplInvDbtDouble mapInvDbtDouble(ResultSet rs) throws SQLException {
        Timestamp statusAt = rs.getTimestamp("ciudStatusAt");
        return new SudzCnInvUplInvDbtDouble(
                rs.getInt("ciudKey"),
                rs.getInt("ciudCidut"),
                getInteger(rs, "ciudDbtFile"),
                rs.getInt("ciudUnloadKey"),
                getInteger(rs, "ciudIKey"),
                rs.getNString("ciudCnNum"),
                rs.getNString("ciudInvNum"),
                rs.getBigDecimal("ciudDebt"),
                getInteger(rs, "ciudIdvvKey"),
                rs.getNString("ciudReason"),
                rs.getNString("ciudReasonDetail"),
                rs.getString("ciudStatus"),
                toOffsetDateTime(statusAt),
                getInteger(rs, "ciudCreatedIdKey")
        );
    }

    private static List<SudzDbtUplCnCtptExistInvContract> loadCnCtptExistInvContracts(
            Connection connection,
            String buf
    ) throws SQLException {
        String sql = "SELECT cidutciCn_key, cidutciCnName, cidutciCnInv, inNumCount "
                + "FROM " + buf + " ORDER BY cidutciCn_key, cidutciRow";
        Map<Integer, List<SudzDbtUplCnCtptExistInvItem>> byCn = new LinkedHashMap<>();
        Map<Integer, String> names = new LinkedHashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                int cnKey = rs.getInt("cidutciCn_key");
                names.putIfAbsent(cnKey, rs.getNString("cidutciCnName"));
                Integer count = (Integer) rs.getObject("inNumCount");
                byCn.computeIfAbsent(cnKey, key -> new ArrayList<>())
                        .add(new SudzDbtUplCnCtptExistInvItem(rs.getNString("cidutciCnInv"), count));
            }
        }
        List<SudzDbtUplCnCtptExistInvContract> contracts = new ArrayList<>();
        for (Map.Entry<Integer, List<SudzDbtUplCnCtptExistInvItem>> entry : byCn.entrySet()) {
            List<SudzDbtUplCnCtptExistInvItem> invoices = entry.getValue();
            contracts.add(new SudzDbtUplCnCtptExistInvContract(
                    entry.getKey(),
                    names.get(entry.getKey()),
                    invoices.size(),
                    invoices
            ));
        }
        return List.copyOf(contracts);
    }

    private SudzDbtUplCnNotLoadInserted insertCnNotLoadChain(
            Connection connection,
            SudzDbtUplCnNotLoad row,
            int cnMark,
            String note,
            Timestamp now
    ) throws SQLException {
        int cnKey;
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO ags.cn (cnTimeOfEntry, cn_note, cnMark) VALUES (?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            statement.setTimestamp(1, now);
            statement.setNString(2, note);
            statement.setInt(3, cnMark);
            statement.executeUpdate();
            cnKey = readGeneratedKey(statement, "Не удалось получить cn_key");
        }
        int cnnKey;
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO ags.cnNum (cnnNum, cnnCn, cnnType, cnnNote, cnnTimeOfEntry) "
                        + "VALUES (?, ?, 1, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            statement.setNString(1, row.cnName());
            statement.setInt(2, cnKey);
            statement.setNString(3, note);
            statement.setTimestamp(4, now);
            statement.executeUpdate();
            cnnKey = readGeneratedKey(statement, "Не удалось получить cnnKey");
        }
        int cnSKey;
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO ags.cn_s (cn_key, cn_s_type) VALUES (?, 2)",
                Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, cnKey);
            statement.executeUpdate();
            cnSKey = readGeneratedKey(statement, "Не удалось получить cn_s_key");
        }
        int csosKey;
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO ags.cn_s_org_smpl (csosCn_s, csosOrgId, csosTimeOfEntry) VALUES (?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, cnSKey);
            statement.setInt(2, row.orgIdKey());
            statement.setTimestamp(3, now);
            statement.executeUpdate();
            csosKey = readGeneratedKey(statement, "Не удалось получить csosKey");
        }
        int cnSOrgKey;
        LocalDate cnDate = row.cnDate();
        boolean writeDate = cnDate != null;
        String insertOrg = writeDate
                ? "INSERT INTO ags.cn_s_org (csoCn_s_org_smpl, csoTimeOfEntry, csoCnDate) VALUES (?, ?, ?)"
                : "INSERT INTO ags.cn_s_org (csoCn_s_org_smpl, csoTimeOfEntry) VALUES (?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(
                insertOrg, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, csosKey);
            statement.setTimestamp(2, now);
            if (writeDate) {
                statement.setDate(3, Date.valueOf(cnDate));
            }
            statement.executeUpdate();
            cnSOrgKey = readGeneratedKey(statement, "Не удалось получить cn_s_org_key");
        }
        return new SudzDbtUplCnNotLoadInserted(cnKey, cnnKey, cnSKey, csosKey, cnSOrgKey);
    }

    private static void bindTblRow(PreparedStatement statement, SudzDbtUplTblRow row) throws SQLException {
        statement.setInt(1, row.findDbtNum());
        statement.setInt(2, row.cidutAccount());
        if (row.cidutCntrPrtNum() == null) {
            statement.setNull(3, Types.INTEGER);
        } else {
            statement.setInt(3, row.cidutCntrPrtNum());
        }
        statement.setNString(4, row.cidutCntrPrtName());
        statement.setNString(5, row.cidutCntrPrtITN());
        statement.setNString(6, row.cidutCnName());
        setTimestamp(statement, 7, row.cidutCnDate());
        statement.setNString(8, row.cidutCnInv());
        setTimestamp(statement, 9, row.cidutFormtnDate());
        setTimestamp(statement, 10, row.cidutMatrtyDate());
        if (row.cidutDebt() == null) {
            statement.setNull(11, Types.DECIMAL);
        } else {
            statement.setBigDecimal(11, row.cidutDebt());
        }
        if (row.cidutDebtOverdue() == null) {
            statement.setNull(12, Types.DECIMAL);
        } else {
            statement.setBigDecimal(12, row.cidutDebtOverdue());
        }
        statement.setNString(13, row.cidutDoc());
        statement.setNString(14, row.cidutLink());
        statement.setInt(15, row.cidutSheet());
        statement.setInt(16, row.cidutSheetNum());
        statement.setInt(17, row.cidutUnloadKey());
    }

    private static void setTimestamp(PreparedStatement statement, int index, LocalDateTime value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.TIMESTAMP);
        } else {
            statement.setTimestamp(index, Timestamp.valueOf(value));
        }
    }

    private Optional<SudzUplLookup> findUplLookupOn(Connection connection, int uplKey) throws SQLException {
        String sql = "SELECT upl_key, upl_name, upl_date, uplStatusOnDate FROM " + q("cn_inv_dbt_upl")
                + " WHERE upl_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(new SudzUplLookup(
                        rs.getInt("upl_key"),
                        rs.getString("upl_name"),
                        getLocalDate(rs, "upl_date"),
                        getLocalDate(rs, "uplStatusOnDate")
                ));
            }
        }
    }

    private Optional<SudzDbtUplFile> findDbtUplFileByUpload(Connection connection, int uplKey)
            throws SQLException {
        String sql = "SELECT cidufKey, cidufUpload, cidufPath, cidufFlLoad, cidufFlTbl, cidufLoadingProgress"
                + " FROM " + q("CnInvDbtUplFile") + " WHERE cidufUpload = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapDbtUplFile(rs));
            }
        }
    }

    private List<SudzDbtUplFileSh> loadDbtUplFileSheets(Connection connection, int fileKey)
            throws SQLException {
        String sql = "SELECT sh.cidufsKey, sh.cidufsFile, sh.cidufsSheet, sh.cidufsAccount, sh.cidufsTest,"
                + " a.account_num AS accountNum"
                + " FROM " + q("CnInvDbtUplFileSh") + " AS sh"
                + " LEFT JOIN ags.accnt AS a ON a.account_key = sh.cidufsAccount"
                + " WHERE sh.cidufsFile = ? ORDER BY sh.cidufsKey";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplFileSh> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(mapDbtUplFileSh(rs));
                }
                return List.copyOf(result);
            }
        }
    }

    private static SudzDbtUplFileSh mapDbtUplFileSh(ResultSet rs) throws SQLException {
        int accountNum = rs.getInt("accountNum");
        return new SudzDbtUplFileSh(
                rs.getInt("cidufsKey"),
                rs.getInt("cidufsFile"),
                rs.getString("cidufsSheet"),
                rs.getInt("cidufsAccount"),
                rs.getBoolean("cidufsTest"),
                rs.wasNull() ? null : accountNum
        );
    }

    /** Стандартные листы общего свода (как Access File=20 / seed 910). */
    private static final int[][] STANDARD_SHEET_ACCNT = {
            {606012, 19},
            {606022, 21},
            {761010, 23},
            {767501, 28},
            {762210, 24},
            {767502, 29}
    };

    /**
     * Гарантирует строку {@code CnInvDbtUplFile} и возвращает {@code cidufKey}.
     *
     * @param connection JDBC
     * @param uplKey {@code upl_key}
     * @return {@code cidufKey}
     */
    private int ensureDbtUplFileKey(Connection connection, int uplKey) throws SQLException {
        ensureUplExists(connection, uplKey);
        Optional<SudzDbtUplFile> existing = findDbtUplFileByUpload(connection, uplKey);
        if (existing.isPresent()) {
            return existing.get().cidufKey();
        }
        String sql = "INSERT INTO " + q("CnInvDbtUplFile")
                + " (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)"
                + " VALUES (?, N'', 0, NULL, 0)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            statement.executeUpdate();
        }
        return findDbtUplFileByUpload(connection, uplKey)
                .orElseThrow(() -> new IllegalStateException(
                        "CnInvDbtUplFile не найден после insert: uplKey=" + uplKey))
                .cidufKey();
    }

    /**
     * Разрешает {@code ags.accnt.account_key} по номеру счёта ГК.
     *
     * @param connection JDBC
     * @param accountNum {@code account_num}
     * @return ключ счёта
     */
    private int resolveAccntKey(Connection connection, int accountNum) throws SQLException {
        if (accountNum <= 0) {
            throw new IllegalArgumentException("accountNum должен быть положительным: " + accountNum);
        }
        String sql = "SELECT account_key FROM ags.accnt WHERE account_num = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, accountNum);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "Счёт ГК не найден в ags.accnt: account_num=" + accountNum);
                }
                return rs.getInt("account_key");
            }
        }
    }

    private Optional<SudzDbtUplFileSh> findDbtUplFileShOn(Connection connection, int cidufsKey)
            throws SQLException {
        String sql = "SELECT sh.cidufsKey, sh.cidufsFile, sh.cidufsSheet, sh.cidufsAccount, sh.cidufsTest,"
                + " a.account_num AS accountNum"
                + " FROM " + q("CnInvDbtUplFileSh") + " AS sh"
                + " LEFT JOIN ags.accnt AS a ON a.account_key = sh.cidufsAccount"
                + " WHERE sh.cidufsKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cidufsKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapDbtUplFileSh(rs));
            }
        }
    }

    @Override
    public SudzDbtUplFileSh createDbtUplFileSh(int uplKey, String sheet, int accountNum, boolean test) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        String sheetNorm = sheet == null ? "" : sheet.trim();
        if (sheetNorm.isEmpty()) {
            throw new IllegalArgumentException("Имя листа не может быть пустым");
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int fileKey = ensureDbtUplFileKey(connection, uplKey);
                int accntKey = resolveAccntKey(connection, accountNum);
                String sql = "INSERT INTO " + q("CnInvDbtUplFileSh")
                        + " (cidufsFile, cidufsSheet, cidufsAccount, cidufsTest)"
                        + " VALUES (?, ?, ?, ?)";
                int newKey;
                try (PreparedStatement statement = connection.prepareStatement(
                        sql, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, fileKey);
                    statement.setString(2, sheetNorm);
                    statement.setInt(3, accntKey);
                    statement.setBoolean(4, test);
                    statement.executeUpdate();
                    newKey = readGeneratedKey(statement, "Не удалось получить cidufsKey");
                }
                connection.commit();
                return findDbtUplFileShOn(connection, newKey)
                        .orElseThrow(() -> new IllegalStateException("FileSh не найден после insert"));
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать CnInvDbtUplFileSh uplKey=" + uplKey, exception);
        }
    }

    @Override
    public SudzDbtUplFileSh updateDbtUplFileSh(int cidufsKey, String sheet, Integer accountNum, Boolean test) {
        if (cidufsKey <= 0) {
            throw new IllegalArgumentException("cidufsKey должен быть положительным: " + cidufsKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzDbtUplFileSh current = findDbtUplFileShOn(connection, cidufsKey)
                        .orElseThrow(() -> new IllegalArgumentException(
                                "Лист загрузки не найден: cidufsKey=" + cidufsKey));
                String newSheet = sheet != null ? sheet.trim() : current.cidufsSheet();
                if (newSheet.isEmpty()) {
                    throw new IllegalArgumentException("Имя листа не может быть пустым");
                }
                int newAccntKey = current.cidufsAccount();
                if (accountNum != null) {
                    newAccntKey = resolveAccntKey(connection, accountNum);
                }
                boolean newTest = test != null ? test : current.cidufsTest();
                String sql = "UPDATE " + q("CnInvDbtUplFileSh")
                        + " SET cidufsSheet = ?, cidufsAccount = ?, cidufsTest = ? WHERE cidufsKey = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, newSheet);
                    statement.setInt(2, newAccntKey);
                    statement.setBoolean(3, newTest);
                    statement.setInt(4, cidufsKey);
                    if (statement.executeUpdate() == 0) {
                        throw new IllegalArgumentException(
                                "Лист загрузки не найден: cidufsKey=" + cidufsKey);
                    }
                }
                connection.commit();
                return findDbtUplFileShOn(connection, cidufsKey)
                        .orElseThrow(() -> new IllegalStateException("FileSh не найден после update"));
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось обновить CnInvDbtUplFileSh cidufsKey=" + cidufsKey, exception);
        }
    }

    @Override
    public boolean deleteDbtUplFileSh(int cidufsKey) {
        if (cidufsKey <= 0) {
            throw new IllegalArgumentException("cidufsKey должен быть положительным: " + cidufsKey);
        }
        String sql = "DELETE FROM " + q("CnInvDbtUplFileSh") + " WHERE cidufsKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cidufsKey);
            return statement.executeUpdate() > 0;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось удалить CnInvDbtUplFileSh cidufsKey=" + cidufsKey, exception);
        }
    }

    @Override
    public List<SudzDbtUplFileSh> seedDbtUplStandardSheets(int uplKey) {
        if (uplKey <= 0) {
            throw new IllegalArgumentException("uplKey должен быть положительным: " + uplKey);
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int fileKey = ensureDbtUplFileKey(connection, uplKey);
                List<SudzDbtUplFileSh> existing = loadDbtUplFileSheets(connection, fileKey);
                if (existing.isEmpty()) {
                    String sql = "INSERT INTO " + q("CnInvDbtUplFileSh")
                            + " (cidufsFile, cidufsSheet, cidufsAccount, cidufsTest) VALUES (?, ?, ?, 1)";
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        for (int[] pair : STANDARD_SHEET_ACCNT) {
                            statement.setInt(1, fileKey);
                            statement.setString(2, String.valueOf(pair[0]));
                            statement.setInt(3, pair[1]);
                            statement.addBatch();
                        }
                        statement.executeBatch();
                    }
                }
                connection.commit();
                return loadDbtUplFileSheets(connection, fileKey);
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось seed стандартных листов uplKey=" + uplKey, exception);
        }
    }

    /**
     * Пересборка {@code CnInvUplSfDouble} для долгов: 1 строка Excel ↔ 1 очередь
     * при {@code inNumCount IS NOT NULL}. Требует заполненных #ciduMatched и буфера.
     */
    private void rebuildDbtSfDoubleQueue(
            Connection connection,
            String tbl,
            String buf,
            int unloadKey,
            int fileKey
    ) throws SQLException {
        String sf = q("CnInvUplSfDouble");
        try (PreparedStatement del = connection.prepareStatement(
                "DELETE FROM " + sf + " WHERE ciusUnloadKey = ? AND ciusCidut IS NOT NULL")) {
            del.setInt(1, unloadKey);
            int deleted = del.executeUpdate();
            log.log(Level.INFO, "CnInvUplSfDouble cleared unloadKey={0} deleted={1}",
                    new Object[]{unloadKey, deleted});
        }
        String insert = ""
                + "INSERT INTO " + sf
                + " (ciusCidut, ciusDbtFile, ciusUnloadKey, ciusDbtTblCnInvRow,"
                + "  ciusCnKey, ciusCnNum, ciusInvNum, ciusInvNumCount, ciusStatus)"
                + " SELECT t.cidutKey, ?, ?, b.cidutciRow,"
                + "        b.cidutciCn_key, b.cidutciCnName, b.cidutciCnInv, b.inNumCount, 'open'"
                + " FROM " + buf + " AS b"
                + " INNER JOIN " + tbl + " AS t ON t.cidutUnloadKey = ?"
                + " INNER JOIN #ciduMatched AS m"
                + "   ON m.cn_key = b.cidutciCn_key"
                + "  AND ((m.cidutCntrPrtNum = t.cidutCntrPrtNum)"
                + "    OR (m.cidutCntrPrtNum IS NULL AND t.cidutCntrPrtNum IS NULL))"
                + "  AND m.cidutCnNameNull = CASE"
                + "        WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N''"
                + "        THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END"
                + "  AND m.cidutCnDateNull = CASE"
                + "        WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date)"
                + "        ELSE CAST(t.cidutCnDate AS date) END"
                + " WHERE b.inNumCount IS NOT NULL"
                + "   AND ("
                + "     CASE WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N''"
                + "          THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END"
                + "   ) = b.cidutciCnInv";
        try (PreparedStatement ps = connection.prepareStatement(insert)) {
            ps.setInt(1, fileKey);
            ps.setInt(2, unloadKey);
            ps.setInt(3, unloadKey);
            int n = ps.executeUpdate();
            log.log(Level.INFO, "CnInvUplSfDouble filled unloadKey={0} rows={1}",
                    new Object[]{unloadKey, n});
        }
    }

    private List<SudzCnInvUplSfDouble> loadSfDoublesByUnload(Connection connection, int unloadKey)
            throws SQLException {
        String sql = "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                + " FROM " + q("CnInvUplSfDouble")
                + " WHERE ciusUnloadKey = ? AND ciusCidut IS NOT NULL"
                + " ORDER BY ciusStatus, ciusKey";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, unloadKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzCnInvUplSfDouble> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(mapSfDouble(rs));
                }
                return List.copyOf(result);
            }
        }
    }

    private static SudzCnInvUplSfDouble mapSfDouble(ResultSet rs) throws SQLException {
        Timestamp statusAt = rs.getTimestamp("ciusStatusAt");
        return new SudzCnInvUplSfDouble(
                rs.getInt("ciusKey"),
                getInteger(rs, "ciusCidut"),
                getInteger(rs, "ciusCiput"),
                getInteger(rs, "ciusDbtFile"),
                getInteger(rs, "ciusPmtFile"),
                getInteger(rs, "ciusUnloadKey"),
                getInteger(rs, "ciusDbtTblCnInvRow"),
                getInteger(rs, "ciusPmtTblCnInvRow"),
                getInteger(rs, "ciusCnKey"),
                rs.getNString("ciusCnNum"),
                rs.getNString("ciusInvNum"),
                getInteger(rs, "ciusInvNumCount"),
                rs.getString("ciusStatus"),
                toOffsetDateTime(statusAt),
                getInteger(rs, "ciusCreatedInvKey")
        );
    }

    @Override
    public List<SudzCnInvUplSfDouble> findSfDoublesByUnload(int unloadKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            return loadSfDoublesByUnload(connection, unloadKey);
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать CnInvUplSfDouble unloadKey=" + unloadKey, exception);
        }
    }

    @Override
    public Optional<SudzSfDoubleExcelCandidate> findSfDoubleExcelCandidate(int ciusKey) {
        String sql = ""
                + "SELECT t.cidutKey, t.FindDbtNum, t.cidutAccount, acc.account_num AS cidutAccntNum,"
                + " t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN, t.cidutCnName, t.cidutCnDate,"
                + " t.cidutCnInv, t.cidutCnInvName, t.cidutFormtnDate, t.cidutMatrtyDate,"
                + " t.cidutDebt, t.cidutDebtOverdue, t.cidutDoc, t.cidutLink,"
                + " t.cidutSheet, t.cidutSheetNum, t.cidutUnloadKey"
                + " FROM " + q("CnInvUplSfDouble") + " AS q"
                + " INNER JOIN " + q("CnInvDbtUplTbl") + " AS t ON t.cidutKey = q.ciusCidut"
                + " LEFT JOIN ags.accnt AS acc ON acc.account_key = t.cidutAccount"
                + " WHERE q.ciusKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciusKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapExcelCandidate(rs));
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать Excel-кандидата ciusKey=" + ciusKey, exception);
        }
    }

    @Override
    public List<SudzSfDoubleDomainMatch> findSfDoubleDomainMatches(String invNum) {
        if (invNum == null || invNum.isBlank() || "NullИлиПусто".equals(invNum)) {
            return List.of();
        }
        String sql = ""
                + "SELECT i.iKey, n.inNum, n.inKey, i.iTimeOfEntry,"
                + " ci.ciKey, ci.ciCn,"
                + " (SELECT TOP 1 num.cnnNumNull FROM ags.cnNum AS num"
                + "  WHERE num.cnnCn = ci.ciCn ORDER BY num.cnnKey) AS cnNum"
                + " FROM ags.invNum AS n"
                + " INNER JOIN ags.inv AS i ON i.iKey = n.inInv"
                + " LEFT JOIN ags.cnInv AS ci ON ci.ciInv = i.iKey"
                + " WHERE n.inNumNull = ?"
                + " ORDER BY i.iKey, ci.ciKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, invNum.trim());
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleDomainMatch> result = new ArrayList<>();
                while (rs.next()) {
                    Timestamp entered = rs.getTimestamp("iTimeOfEntry");
                    result.add(new SudzSfDoubleDomainMatch(
                            rs.getInt("iKey"),
                            rs.getNString("inNum"),
                            getInteger(rs, "inKey"),
                            toOffsetDateTime(entered),
                            getInteger(rs, "ciKey"),
                            getInteger(rs, "ciCn"),
                            rs.getNString("cnNum")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось найти доменные СФ по номеру", exception);
        }
    }

    @Override
    public SudzSfDoubleSumMatches findSfDoubleSumMatches(BigDecimal debt, BigDecimal epsilon) {
        Objects.requireNonNull(debt, "debt");
        Objects.requireNonNull(epsilon, "epsilon");
        List<SudzSfDoubleOldSumMatch> oldMatches = findOldSumMatches(debt, epsilon);
        List<SudzSfDoubleNewSumMatch> newMatches = findNewSumMatches(debt, epsilon);
        log.log(
                Level.FINE,
                "SfDouble sum matches debt={0} eps={1}: old={2} new={3}",
                new Object[] {debt, epsilon, oldMatches.size(), newMatches.size()}
        );
        return new SudzSfDoubleSumMatches(oldMatches, newMatches);
    }

    private static final int HINT_ITEM_LIMIT = 20;

    @Override
    public SudzSfDoubleHints findSfDoubleHints(int ciusKey, BigDecimal epsilon) {
        Objects.requireNonNull(epsilon, "epsilon");
        Optional<SudzSfDoubleExcelCandidate> excelOpt = findSfDoubleExcelCandidate(ciusKey);
        if (excelOpt.isEmpty()) {
            SudzSfDoubleHintSection empty = section(
                    "na",
                    "Строка очереди / Excel-кандидат не найдены.",
                    0,
                    List.of()
            );
            return new SudzSfDoubleHints(empty, empty, empty);
        }
        SudzSfDoubleExcelCandidate excel = excelOpt.get();
        Integer buirg = excel.cidutCntrPrtNum();
        String itn = blankToNull(excel.cidutCntrPrtITN());
        boolean hasAnchor = buirg != null || itn != null;

        String invNum = loadSfDoubleInvNum(ciusKey);
        SudzSfDoubleHintSection sfByNum;
        if (invNum == null || invNum.isBlank() || "NullИлиПусто".equals(invNum)) {
            sfByNum = section("na", "В очереди нет номера СФ для проверки.", 0, List.of());
        } else if (!hasAnchor) {
            sfByNum = section(
                    "unknown",
                    "В Excel нет БУиРГ и ИНН контрагента — проверку исполнителя по СФ выполнить нельзя.",
                    0,
                    List.of()
            );
        } else {
            List<SudzSfDoubleHintItem> items = findSfHintItemsByInvNum(invNum, buirg, itn);
            sfByNum = buildCtptSection(
                    "СФ с совпадающими номерами",
                    items,
                    "inKey"
            );
        }

        BigDecimal debt = excel.cidutDebt();
        SudzSfDoubleHintSection sumsOld;
        SudzSfDoubleHintSection sumsNew;
        if (debt == null) {
            SudzSfDoubleHintSection noDebt = section(
                    "na",
                    "В Excel нет суммы (cidutDebt) — проверку по суммам выполнить нельзя.",
                    0,
                    List.of()
            );
            sumsOld = noDebt;
            sumsNew = noDebt;
        } else if (!hasAnchor) {
            SudzSfDoubleHintSection noCtpt = section(
                    "unknown",
                    "В Excel нет БУиРГ и ИНН контрагента — проверку исполнителя по суммам выполнить нельзя.",
                    0,
                    List.of()
            );
            sumsOld = noCtpt;
            sumsNew = noCtpt;
        } else {
            sumsOld = buildCtptSection(
                    "совпадающих суммах (старая структура)",
                    findOldSumHintItems(debt, epsilon, buirg, itn),
                    "cidKey"
            );
            sumsNew = buildCtptSection(
                    "совпадающих суммах (новая структура)",
                    findNewSumHintItems(debt, epsilon, buirg, itn),
                    "dvKey"
            );
        }
        return new SudzSfDoubleHints(sfByNum, sumsOld, sumsNew);
    }

    @Override
    public SudzSfDoubleAdvice findSfDoubleAdvice(int ciusKey, BigDecimal epsilon) {
        if (ciusKey <= 0) {
            throw new IllegalArgumentException("ciusKey должен быть положительным: " + ciusKey);
        }
        Objects.requireNonNull(epsilon, "epsilon");
        SudzCnInvUplSfDouble row = loadSfDoubleByKey(ciusKey);
        SudzSfDoubleExcelCandidate excel = findSfDoubleExcelCandidate(ciusKey).orElse(null);
        SudzSfDoubleHints hints = findSfDoubleHints(ciusKey, epsilon);
        String invNum = row.ciusInvNum();
        List<SudzSfDoubleDomainMatch> domain = (invNum != null && !invNum.isBlank())
                ? findSfDoubleDomainMatches(invNum)
                : List.of();
        return SfDoubleAdvisor.advise(row, excel, hints, domain);
    }

    /**
     * Загружает строку очереди КСДСФ по ключу.
     *
     * @param ciusKey ключ
     * @return строка
     */
    private SudzCnInvUplSfDouble loadSfDoubleByKey(int ciusKey) {
        String sql = "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                + " FROM " + q("CnInvUplSfDouble") + " WHERE ciusKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciusKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Строка очереди не найдена: " + ciusKey);
                }
                return mapSfDouble(rs);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать очередь ciusKey=" + ciusKey, exception);
        }
    }

    /**
     * Собирает секцию yes/no с усечением списка ключей.
     */
    private static SudzSfDoubleHintSection buildCtptSection(
            String whereRu,
            List<SudzSfDoubleHintItem> all,
            String pickKeyRu
    ) {
        int total = all.size();
        List<SudzSfDoubleHintItem> shown = all.size() > HINT_ITEM_LIMIT
                ? List.copyOf(all.subList(0, HINT_ITEM_LIMIT))
                : all;
        if (total == 0) {
            return section(
                    "no",
                    "В " + whereRu + " совпадающего контрагента (исполнитель) нет.",
                    0,
                    List.of()
            );
        }
        String more = total > shown.size() ? " (показаны первые " + shown.size() + " из " + total + ")" : "";
        return section(
                "yes",
                "В " + whereRu + " есть совпадающий контрагент (исполнитель)"
                        + more + ". Ключи для выбора: " + pickKeyRu + ".",
                total,
                shown
        );
    }

    private static SudzSfDoubleHintSection section(
            String status,
            String message,
            int totalCount,
            List<SudzSfDoubleHintItem> items
    ) {
        return new SudzSfDoubleHintSection(status, message, totalCount, List.copyOf(items));
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /**
     * Номер СФ из строки очереди.
     */
    private String loadSfDoubleInvNum(int ciusKey) {
        String sql = "SELECT ciusInvNum FROM " + q("CnInvUplSfDouble") + " WHERE ciusKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciusKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getNString("ciusInvNum");
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось прочитать ciusInvNum для ciusKey=" + ciusKey, exception);
        }
    }

    /**
     * SQL-фрагмент: org исполнителя совпадает с Excel по БУиРГ или ИНН (через og).
     */
    private static String executorOrgMatchSql(String orgIdAlias) {
        return "("
                + " (" + orgIdAlias + ".org_id_type = 1 AND ? IS NOT NULL"
                + " AND " + orgIdAlias + ".org_id_value_l = ?)"
                + " OR (" + orgIdAlias + ".org_id_type = 2 AND ? IS NOT NULL"
                + " AND " + orgIdAlias + ".org_id_value_t = ?)"
                + " OR EXISTS ("
                + "   SELECT 1 FROM ags.org_id alt"
                + "   WHERE alt.org = " + orgIdAlias + ".org"
                + "     AND (("
                + "       alt.org_id_type = 1 AND ? IS NOT NULL AND alt.org_id_value_l = ?"
                + "     ) OR ("
                + "       alt.org_id_type = 2 AND ? IS NOT NULL AND alt.org_id_value_t = ?"
                + "     ))"
                + " )"
                + ")";
    }

    /**
     * Биндит 8 параметров якоря (buirg×4 + itn×4 в порядке executorOrgMatchSql).
     */
    private static void bindExecutorAnchors(
            PreparedStatement statement,
            int startIndex,
            Integer buirg,
            String itn
    ) throws SQLException {
        int i = startIndex;
        // type=1 direct
        if (buirg == null) {
            statement.setNull(i++, Types.INTEGER);
            statement.setNull(i++, Types.INTEGER);
        } else {
            statement.setInt(i++, buirg);
            statement.setInt(i++, buirg);
        }
        // type=2 direct
        if (itn == null) {
            statement.setNull(i++, Types.NVARCHAR);
            statement.setNull(i++, Types.NVARCHAR);
        } else {
            statement.setNString(i++, itn);
            statement.setNString(i++, itn);
        }
        // EXISTS type=1
        if (buirg == null) {
            statement.setNull(i++, Types.INTEGER);
            statement.setNull(i++, Types.INTEGER);
        } else {
            statement.setInt(i++, buirg);
            statement.setInt(i++, buirg);
        }
        // EXISTS type=2
        if (itn == null) {
            statement.setNull(i++, Types.NVARCHAR);
            statement.setNull(i, Types.NVARCHAR);
        } else {
            statement.setNString(i++, itn);
            statement.setNString(i, itn);
        }
    }

    private static String resolveMatchBy(ResultSet rs, Integer buirg, String itn) throws SQLException {
        boolean byBuirg = false;
        boolean byItn = false;
        if (buirg != null) {
            Integer v = (Integer) rs.getObject("hitBuirg");
            byBuirg = v != null && v == 1;
        }
        if (itn != null) {
            Integer v = (Integer) rs.getObject("hitItn");
            byItn = v != null && v == 1;
        }
        if (byBuirg && byItn) {
            return "BOTH";
        }
        if (byBuirg) {
            return "BUIRG";
        }
        if (byItn) {
            return "ITN";
        }
        return "BUIRG";
    }

    private List<SudzSfDoubleHintItem> findSfHintItemsByInvNum(
            String invNum,
            Integer buirg,
            String itn
    ) {
        String sql = ""
                + "SELECT DISTINCT n.inKey, i.iKey AS invKey, ci.ciCn AS cnKey,"
                + " (SELECT TOP 1 num.cnnNumNull FROM ags.cnNum AS num"
                + "  WHERE num.cnnCn = ci.ciCn ORDER BY num.cnnKey) AS cnNum,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 1 AND hx.org_id_value_l = ?"
                + " ) THEN 1 ELSE 0 END AS hitBuirg,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 2 AND hx.org_id_value_t = ?"
                + " ) THEN 1 ELSE 0 END AS hitItn"
                + " FROM ags.invNum AS n"
                + " INNER JOIN ags.inv AS i ON i.iKey = n.inInv"
                + " INNER JOIN ags.cnInv AS ci ON ci.ciInv = i.iKey"
                + " INNER JOIN ags.cn_s AS s ON s.cn_key = ci.ciCn AND s.cn_s_type = 2"
                + " INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key"
                + " INNER JOIN ags.org_id AS oi ON oi.org_id_key = m.csosOrgId"
                + " WHERE n.inNumNull = ?"
                + "   AND " + executorOrgMatchSql("oi")
                + " ORDER BY n.inKey, i.iKey, ci.ciCn";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int p = 1;
            if (buirg == null) {
                statement.setNull(p++, Types.INTEGER);
                statement.setNull(p++, Types.INTEGER);
            } else {
                statement.setInt(p++, buirg);
                statement.setInt(p++, buirg);
            }
            if (itn == null) {
                statement.setNull(p++, Types.NVARCHAR);
                statement.setNull(p++, Types.NVARCHAR);
            } else {
                statement.setNString(p++, itn);
                statement.setNString(p++, itn);
            }
            statement.setNString(p++, invNum.trim());
            bindExecutorAnchors(statement, p, buirg, itn);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleHintItem> result = new ArrayList<>();
                while (rs.next()) {
                    int inKey = rs.getInt("inKey");
                    Integer invKey = getInteger(rs, "invKey");
                    Integer cnKey = getInteger(rs, "cnKey");
                    String cnNum = rs.getNString("cnNum");
                    String matchBy = resolveMatchBy(rs, buirg, itn);
                    result.add(new SudzSfDoubleHintItem(
                            "sf",
                            "inKey",
                            inKey,
                            invKey,
                            cnKey,
                            cnNum,
                            matchBy,
                            "inKey=" + inKey
                                    + (cnKey != null ? " · cn=" + cnKey : "")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось проверить контрагента среди СФ по номеру", exception);
        }
    }

    private List<SudzSfDoubleHintItem> findOldSumHintItems(
            BigDecimal debt,
            BigDecimal epsilon,
            Integer buirg,
            String itn
    ) {
        String sql = ""
                + "SELECT DISTINCT d.cn_inv_dbt_key AS cidKey, ci.ciCn AS cnKey,"
                + " (SELECT TOP 1 num.cnnNumNull FROM ags.cnNum AS num"
                + "  WHERE num.cnnCn = ci.ciCn ORDER BY num.cnnKey) AS cnNum,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 1 AND hx.org_id_value_l = ?"
                + " ) THEN 1 ELSE 0 END AS hitBuirg,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 2 AND hx.org_id_value_t = ?"
                + " ) THEN 1 ELSE 0 END AS hitItn"
                + " FROM ags.cn_inv_dbt AS d"
                + " INNER JOIN ags.cnInvAccnt AS cia ON cia.ciaKey = d.cidCnInvAccntCtpt"
                + " INNER JOIN ags.cn_s_org AS cso ON cso.cn_s_org_key = cia.ciaCn_s_org"
                + " INNER JOIN ags.cn_s_org_smpl AS m ON m.csosKey = cso.csoCn_s_org_smpl"
                + " INNER JOIN ags.cn_s AS s ON s.cn_s_key = m.csosCn_s AND s.cn_s_type = 2"
                + " INNER JOIN ags.org_id AS oi ON oi.org_id_key = m.csosOrgId"
                + " LEFT JOIN ags.cnInvAccntSmpl AS cias ON cias.ciasKey = cia.ciaCnInvAccntSmpl"
                + " LEFT JOIN ags.cnInv AS ci ON ci.ciKey = cias.ciasCnInv"
                + " WHERE ABS(CAST(d.dbt_ttl AS decimal(19,4)) - ?) <= ?"
                + "   AND " + executorOrgMatchSql("oi")
                + " ORDER BY d.cn_inv_dbt_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int p = 1;
            if (buirg == null) {
                statement.setNull(p++, Types.INTEGER);
                statement.setNull(p++, Types.INTEGER);
            } else {
                statement.setInt(p++, buirg);
                statement.setInt(p++, buirg);
            }
            if (itn == null) {
                statement.setNull(p++, Types.NVARCHAR);
                statement.setNull(p++, Types.NVARCHAR);
            } else {
                statement.setNString(p++, itn);
                statement.setNString(p++, itn);
            }
            statement.setBigDecimal(p++, debt);
            statement.setBigDecimal(p++, epsilon);
            bindExecutorAnchors(statement, p, buirg, itn);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleHintItem> result = new ArrayList<>();
                while (rs.next()) {
                    int cidKey = rs.getInt("cidKey");
                    Integer cnKey = getInteger(rs, "cnKey");
                    String cnNum = rs.getNString("cnNum");
                    String matchBy = resolveMatchBy(rs, buirg, itn);
                    result.add(new SudzSfDoubleHintItem(
                            "sumsOld",
                            "cidKey",
                            cidKey,
                            null,
                            cnKey,
                            cnNum,
                            matchBy,
                            "cidKey=" + cidKey
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось проверить контрагента среди cn_inv_dbt по сумме", exception);
        }
    }

    private List<SudzSfDoubleHintItem> findNewSumHintItems(
            BigDecimal debt,
            BigDecimal epsilon,
            Integer buirg,
            String itn
    ) {
        String dv = q("DbtValue");
        String invDbt = q("invDbt");
        String sql = ""
                + "SELECT DISTINCT dv.dvKey, ci.ciCn AS cnKey,"
                + " (SELECT TOP 1 num.cnnNumNull FROM ags.cnNum AS num"
                + "  WHERE num.cnnCn = ci.ciCn ORDER BY num.cnnKey) AS cnNum,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 1 AND hx.org_id_value_l = ?"
                + " ) THEN 1 ELSE 0 END AS hitBuirg,"
                + " CASE WHEN ? IS NOT NULL AND EXISTS ("
                + "   SELECT 1 FROM ags.org_id hx WHERE hx.org = oi.org"
                + "     AND hx.org_id_type = 2 AND hx.org_id_value_t = ?"
                + " ) THEN 1 ELSE 0 END AS hitItn"
                + " FROM " + dv + " AS dv"
                + " INNER JOIN " + invDbt + " AS idb ON idb.idKey = dv.dvInvDbt"
                + " INNER JOIN ags.inv AS i0 ON i0.iKey = idb.idInv"
                + " INNER JOIN ags.cnInv AS ci ON ci.ciInv = i0.iKey"
                + " INNER JOIN ags.cn_s AS s ON s.cn_key = ci.ciCn AND s.cn_s_type = 2"
                + " INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key"
                + " INNER JOIN ags.org_id AS oi ON oi.org_id_key = m.csosOrgId"
                + " WHERE ABS(CAST(dv.dvTtl AS decimal(19,4)) - ?) <= ?"
                + "   AND " + executorOrgMatchSql("oi")
                + " ORDER BY dv.dvKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int p = 1;
            if (buirg == null) {
                statement.setNull(p++, Types.INTEGER);
                statement.setNull(p++, Types.INTEGER);
            } else {
                statement.setInt(p++, buirg);
                statement.setInt(p++, buirg);
            }
            if (itn == null) {
                statement.setNull(p++, Types.NVARCHAR);
                statement.setNull(p++, Types.NVARCHAR);
            } else {
                statement.setNString(p++, itn);
                statement.setNString(p++, itn);
            }
            statement.setBigDecimal(p++, debt);
            statement.setBigDecimal(p++, epsilon);
            bindExecutorAnchors(statement, p, buirg, itn);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleHintItem> result = new ArrayList<>();
                while (rs.next()) {
                    int dvKey = rs.getInt("dvKey");
                    Integer cnKey = getInteger(rs, "cnKey");
                    String cnNum = rs.getNString("cnNum");
                    String matchBy = resolveMatchBy(rs, buirg, itn);
                    result.add(new SudzSfDoubleHintItem(
                            "sumsNew",
                            "dvKey",
                            dvKey,
                            null,
                            cnKey,
                            cnNum,
                            matchBy,
                            "dvKey=" + dvKey
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось проверить контрагента среди DbtValue по сумме", exception);
        }
    }

    /**
     * Старые суммы ({@code ags.cn_inv_dbt}) с {@code ABS(dbt_ttl − debt) ≤ ε}.
     *
     * @param debt якорь Excel
     * @param epsilon допуск
     * @return до 200 строк
     */
    private List<SudzSfDoubleOldSumMatch> findOldSumMatches(BigDecimal debt, BigDecimal epsilon) {
        String sql = ""
                + "SELECT TOP 200 d.cn_inv_dbt_key, d.number, d.dbt_ttl, d.dbt_overd, d.debt_type,"
                + " d.cn_inv_dbt_upl, d.cidCnInvAccntCtpt, a.ciaName"
                + " FROM ags.cn_inv_dbt AS d"
                + " LEFT JOIN ags.cnInvAccnt AS a ON a.ciaKey = d.cidCnInvAccntCtpt"
                + " WHERE ABS(CAST(d.dbt_ttl AS decimal(19,4)) - ?) <= ?"
                + " ORDER BY d.cn_inv_dbt_key";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setBigDecimal(1, debt);
            statement.setBigDecimal(2, epsilon);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleOldSumMatch> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(new SudzSfDoubleOldSumMatch(
                            rs.getInt("cn_inv_dbt_key"),
                            getInteger(rs, "number"),
                            rs.getBigDecimal("dbt_ttl"),
                            rs.getBigDecimal("dbt_overd"),
                            rs.getNString("debt_type"),
                            getInteger(rs, "cn_inv_dbt_upl"),
                            getInteger(rs, "cidCnInvAccntCtpt"),
                            rs.getNString("ciaName")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось найти cn_inv_dbt по сумме", exception);
        }
    }

    /**
     * Новые суммы ({@code sudz.DbtValue} / схема СУДЗ) с {@code ABS(dvTtl − debt) ≤ ε}.
     *
     * @param debt якорь Excel
     * @param epsilon допуск
     * @return до 200 строк
     */
    private List<SudzSfDoubleNewSumMatch> findNewSumMatches(BigDecimal debt, BigDecimal epsilon) {
        String dv = q("DbtValue");
        String idd = q("invDbtDbt");
        String sql = ""
                + "SELECT TOP 200 dv.dvKey, dv.dvTtl, dv.dvOverd, dv.dvUpl, dv.dvInvDbt,"
                + " idd.iddDbt AS dbtKey"
                + " FROM " + dv + " AS dv"
                + " LEFT JOIN " + idd + " AS idd ON idd.iddInvDbt = dv.dvInvDbt"
                + " WHERE ABS(CAST(dv.dvTtl AS decimal(19,4)) - ?) <= ?"
                + " ORDER BY dv.dvKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setBigDecimal(1, debt);
            statement.setBigDecimal(2, epsilon);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzSfDoubleNewSumMatch> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(new SudzSfDoubleNewSumMatch(
                            rs.getInt("dvKey"),
                            rs.getBigDecimal("dvTtl"),
                            rs.getBigDecimal("dvOverd"),
                            getInteger(rs, "dvUpl"),
                            getInteger(rs, "dvInvDbt"),
                            getInteger(rs, "dbtKey")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось найти DbtValue по сумме", exception);
        }
    }

    @Override
    public SudzCnInvUplSfDouble createSfFromDouble(int ciusKey) {
        String sf = q("CnInvUplSfDouble");
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzCnInvUplSfDouble row;
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                                + " FROM " + sf + " WHERE ciusKey = ?")) {
                    ps.setInt(1, ciusKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Строка очереди не найдена: " + ciusKey);
                        }
                        row = mapSfDouble(rs);
                    }
                }
                if (!"open".equals(row.ciusStatus())) {
                    throw new IllegalArgumentException(
                            "Создать СФ можно только со статусом open, сейчас: " + row.ciusStatus());
                }
                if (row.ciusCnKey() == null || row.ciusCnKey() <= 0) {
                    throw new IllegalArgumentException("У строки очереди нет cnKey");
                }
                int invKey;
                try (PreparedStatement inv = connection.prepareStatement(
                        "INSERT INTO ags.inv (iTimeOfEntry) VALUES (?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    inv.setTimestamp(1, now);
                    inv.executeUpdate();
                    invKey = readGeneratedKey(inv, "Не удалось получить iKey");
                }
                try (PreparedStatement invNum = connection.prepareStatement(
                        "INSERT INTO ags.invNum (inNum, inInv, inTimeOfEntry) VALUES (?, ?, ?)")) {
                    String cnInv = row.ciusInvNum();
                    if (cnInv == null || cnInv.isBlank() || "NullИлиПусто".equals(cnInv)) {
                        invNum.setNull(1, Types.NVARCHAR);
                    } else {
                        invNum.setNString(1, cnInv);
                    }
                    invNum.setInt(2, invKey);
                    invNum.setTimestamp(3, now);
                    invNum.executeUpdate();
                }
                try (PreparedStatement cnInvPs = connection.prepareStatement(
                        "INSERT INTO ags.cnInv (ciInv, ciCn, ciTimeOfEntry) VALUES (?, ?, ?)")) {
                    cnInvPs.setInt(1, invKey);
                    cnInvPs.setInt(2, row.ciusCnKey());
                    cnInvPs.setTimestamp(3, now);
                    cnInvPs.executeUpdate();
                }
                try (PreparedStatement upd = connection.prepareStatement(
                        "UPDATE " + sf
                                + " SET ciusStatus = 'created', ciusStatusAt = ?, ciusCreatedInvKey = ?"
                                + " WHERE ciusKey = ?")) {
                    upd.setTimestamp(1, now);
                    upd.setInt(2, invKey);
                    upd.setInt(3, ciusKey);
                    upd.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "createSfFromDouble ciusKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciusKey, invKey, row.ciusCnKey()});
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                                + " FROM " + sf + " WHERE ciusKey = ?")) {
                    ps.setInt(1, ciusKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        return mapSfDouble(rs);
                    }
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось создать СФ из очереди ciusKey=" + ciusKey, exception);
        }
    }

    @Override
    public SudzCnInvUplSfDouble linkSfDoubleToCn(int ciusKey, int invKey, int cnKey) {
        String sf = q("CnInvUplSfDouble");
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                SudzCnInvUplSfDouble row;
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                                + " FROM " + sf + " WHERE ciusKey = ?")) {
                    ps.setInt(1, ciusKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Строка очереди не найдена: " + ciusKey);
                        }
                        row = mapSfDouble(rs);
                    }
                }
                if (!"open".equals(row.ciusStatus())) {
                    throw new IllegalArgumentException(
                            "Привязать можно только строку со статусом open, сейчас: " + row.ciusStatus());
                }
                if (!recordExists(connection, "SELECT 1 FROM ags.inv WHERE iKey = ?", invKey)) {
                    throw new IllegalArgumentException("СФ inv не найден: " + invKey);
                }
                if (!recordExists(connection, "SELECT 1 FROM ags.cn WHERE cn_key = ?", cnKey)) {
                    throw new IllegalArgumentException("Договор cn не найден: " + cnKey);
                }
                if (!recordExists(connection, "SELECT 1 FROM ags.cnInv WHERE ciInv = ? AND ciCn = ?", invKey, cnKey)) {
                    try (PreparedStatement cnInvPs = connection.prepareStatement(
                            "INSERT INTO ags.cnInv (ciInv, ciCn, ciTimeOfEntry) VALUES (?, ?, ?)")) {
                        cnInvPs.setInt(1, invKey);
                        cnInvPs.setInt(2, cnKey);
                        cnInvPs.setTimestamp(3, now);
                        cnInvPs.executeUpdate();
                    }
                }
                String cnNum = loadCnNum(connection, cnKey);
                try (PreparedStatement upd = connection.prepareStatement(
                        "UPDATE " + sf
                                + " SET ciusCnKey = ?, ciusCnNum = ?, ciusStatus = 'created',"
                                + " ciusStatusAt = ?, ciusCreatedInvKey = ? WHERE ciusKey = ?")) {
                    upd.setInt(1, cnKey);
                    if (cnNum == null || cnNum.isBlank()) {
                        upd.setNull(2, Types.NVARCHAR);
                    } else {
                        upd.setNString(2, cnNum);
                    }
                    upd.setTimestamp(3, now);
                    upd.setInt(4, invKey);
                    upd.setInt(5, ciusKey);
                    upd.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "linkSfDoubleToCn ciusKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciusKey, invKey, cnKey});
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT ciusKey, ciusCidut, ciusCiput, ciusDbtFile, ciusPmtFile, ciusUnloadKey,"
                                + " ciusDbtTblCnInvRow, ciusPmtTblCnInvRow, ciusCnKey, ciusCnNum, ciusInvNum,"
                                + " ciusInvNumCount, ciusStatus, ciusStatusAt, ciusCreatedInvKey"
                                + " FROM " + sf + " WHERE ciusKey = ?")) {
                    ps.setInt(1, ciusKey);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        return mapSfDouble(rs);
                    }
                }
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось привязать строку очереди ciusKey=" + ciusKey, exception);
        }
    }

    private static java.time.LocalDate toLocalDate(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime().toLocalDate();
    }

    /**
     * Проверка существования одной записи по простому запросу.
     */
    private static boolean recordExists(Connection connection, String sql, int... params) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                statement.setInt(i + 1, params[i]);
            }
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Берёт первый номер договора для показа в очереди после ручной привязки.
     */
    private static String loadCnNum(Connection connection, int cnKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT TOP 1 cnnNum FROM ags.cnNum WHERE cnnCn = ? ORDER BY cnnKey")) {
            statement.setInt(1, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getNString("cnnNum") : null;
            }
        }
    }

    /**
     * GraphQL {@code DateTime} сериализует {@link OffsetDateTime}; SQL {@code datetime} без зоны
     * трактуем как системное локальное время.
     *
     * @param ts метка из JDBC
     * @return OffsetDateTime или {@code null}
     */
    private static OffsetDateTime toOffsetDateTime(Timestamp ts) {
        if (ts == null) {
            return null;
        }
        return ts.toLocalDateTime().atZone(ZoneId.systemDefault()).toOffsetDateTime();
    }

    private List<SudzDbtUplInvDouble> loadDbtUplInvDoubles(Connection connection, int fileKey)
            throws SQLException {
        String sql = "SELECT cidufiKey, cidufiCiduf, cidufiCnNnn, cidufiCnNum, cidufiCnKey,"
                + " cidufiInvNnn, cidufiInvNum, cidufiInvNumCount"
                + " FROM " + q("CnInvDbtUplFileInvDouble")
                + " WHERE cidufiCiduf = ? ORDER BY cidufiKey";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplInvDouble> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(new SudzDbtUplInvDouble(
                            rs.getInt("cidufiKey"),
                            getInteger(rs, "cidufiCiduf"),
                            getInteger(rs, "cidufiCnNnn"),
                            rs.getString("cidufiCnNum"),
                            getInteger(rs, "cidufiCnKey"),
                            getInteger(rs, "cidufiInvNnn"),
                            rs.getString("cidufiInvNum"),
                            rs.getString("cidufiInvNumCount")
                    ));
                }
                return List.copyOf(result);
            }
        }
    }

    private static SudzDbtUplFile mapDbtUplFile(ResultSet rs) throws SQLException {
        return new SudzDbtUplFile(
                rs.getInt("cidufKey"),
                rs.getInt("cidufUpload"),
                rs.getString("cidufPath"),
                rs.getBoolean("cidufFlLoad"),
                rs.getBoolean("cidufFlTbl"),
                rs.getString("cidufLoadingProgress")
        );
    }

    private String yearSelectSql() {
        return "SELECT y.yr_key, y.yr_variant, y.cn_inv_dbt_upl, y.yyyy, y.yr_CmmGr, y.yr_CmmGr_New, y.yr_Progress, "
                + "u.upl_name AS base_upl_name, u.upl_date AS base_upl_date, "
                + "g.cnicgName AS cmm_gr_name, g.cnicgDate AS cmm_gr_date, "
                + "gn.cnicgName AS cmm_gr_new_name, gn.cnicgDate AS cmm_gr_new_date, "
                + "yy.yyyy AS yyyy_value "
                + "FROM " + q("yr") + " y "
                + "LEFT JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = y.cn_inv_dbt_upl "
                + "LEFT JOIN " + q("cnInvCmmGr") + " g ON g.cnicgKey = y.yr_CmmGr "
                + "LEFT JOIN " + q("cnInvCmmGr") + " gn ON gn.cnicgKey = y.yr_CmmGr_New "
                + "LEFT JOIN ags.yyyy yy ON yy.yKey = y.yyyy";
    }

    private Optional<SudzYear> findYearOn(Connection connection, int yrKey) throws SQLException {
        String sql = yearSelectSql() + " WHERE y.yr_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapYear(rs));
            }
        }
    }

    private List<SudzYearUpl> loadYearUpls(Connection connection, int yrKey) throws SQLException {
        String sql = "SELECT yp.yr_upl_p_key, yp.yr_upl_p_yr, yp.cn_inv_dbt_upl, "
                + "u.upl_name, u.upl_date, u.uplStatusOnDate "
                + "FROM " + q("yr_upl_p") + " yp "
                + "JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = yp.cn_inv_dbt_upl "
                + "WHERE yp.yr_upl_p_yr = ? "
                + "ORDER BY u.upl_date, yp.cn_inv_dbt_upl";
        List<SudzYearUpl> bare = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    bare.add(new SudzYearUpl(
                            rs.getInt("yr_upl_p_key"),
                            rs.getInt("yr_upl_p_yr"),
                            rs.getInt("cn_inv_dbt_upl"),
                            rs.getString("upl_name"),
                            getLocalDate(rs, "upl_date"),
                            getLocalDate(rs, "uplStatusOnDate"),
                            List.of()
                    ));
                }
            }
        }
        if (bare.isEmpty()) {
            return List.of();
        }

        Map<Integer, List<SudzPmLink>> linksByUpl = loadPmLinksForYear(connection, yrKey);
        List<SudzYearUpl> result = new ArrayList<>(bare.size());
        for (SudzYearUpl upl : bare) {
            List<SudzPmLink> links = linksByUpl.getOrDefault(upl.uplKey(), List.of());
            result.add(new SudzYearUpl(
                    upl.yrUplPKey(), upl.yrKey(), upl.uplKey(),
                    upl.uplName(), upl.uplDate(), upl.uplStatusOnDate(),
                    List.copyOf(links)
            ));
        }
        return List.copyOf(result);
    }

    private Map<Integer, List<SudzPmLink>> loadPmLinksForYear(Connection connection, int yrKey)
            throws SQLException {
        String sql = "SELECT gp.[key] AS g_p_key, gp.cn_inv_dbt_upl, gp.cn_inv_pm_upl, "
                + "pm.cn_inv_pm_name, pm.cn_inv_pm_date, "
                + "u.upl_name, u.upl_date "
                + "FROM " + q("cn_inv_dbt_upl_g_p") + " gp "
                + "JOIN " + q("yr_upl_p") + " yp ON yp.cn_inv_dbt_upl = gp.cn_inv_dbt_upl "
                + "JOIN " + q("cn_inv_pm_upl") + " pm ON pm.cn_inv_pm_key = gp.cn_inv_pm_upl "
                + "JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = gp.cn_inv_dbt_upl "
                + "WHERE yp.yr_upl_p_yr = ? "
                + "ORDER BY gp.cn_inv_dbt_upl, pm.cn_inv_pm_date, gp.[key]";
        Map<Integer, List<SudzPmLink>> result = new LinkedHashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    int dbtUpl = rs.getInt("cn_inv_dbt_upl");
                    result.computeIfAbsent(dbtUpl, ignored -> new ArrayList<>())
                            .add(mapPmLink(rs));
                }
            }
        }
        return result;
    }

    private SudzYearUpl loadYearUpl(Connection connection, int yrUplPKey) throws SQLException {
        String sql = "SELECT yp.yr_upl_p_key, yp.yr_upl_p_yr, yp.cn_inv_dbt_upl, "
                + "u.upl_name, u.upl_date, u.uplStatusOnDate "
                + "FROM " + q("yr_upl_p") + " yp "
                + "JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = yp.cn_inv_dbt_upl "
                + "WHERE yp.yr_upl_p_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yrUplPKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Строка yr_upl_p не найдена: key=" + yrUplPKey);
                }
                int uplKey = rs.getInt("cn_inv_dbt_upl");
                int yrKey = rs.getInt("yr_upl_p_yr");
                List<SudzPmLink> links = loadPmLinksForYear(connection, yrKey)
                        .getOrDefault(uplKey, List.of());
                return new SudzYearUpl(
                        rs.getInt("yr_upl_p_key"),
                        yrKey,
                        uplKey,
                        rs.getString("upl_name"),
                        getLocalDate(rs, "upl_date"),
                        getLocalDate(rs, "uplStatusOnDate"),
                        List.copyOf(links)
                );
            }
        }
    }

    private SudzPmLink loadPmLink(Connection connection, int gPKey) throws SQLException {
        String sql = "SELECT gp.[key] AS g_p_key, gp.cn_inv_dbt_upl, gp.cn_inv_pm_upl, "
                + "pm.cn_inv_pm_name, pm.cn_inv_pm_date, "
                + "u.upl_name, u.upl_date "
                + "FROM " + q("cn_inv_dbt_upl_g_p") + " gp "
                + "JOIN " + q("cn_inv_pm_upl") + " pm ON pm.cn_inv_pm_key = gp.cn_inv_pm_upl "
                + "JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = gp.cn_inv_dbt_upl "
                + "WHERE gp.[key] = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, gPKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Связь g_p не найдена: key=" + gPKey);
                }
                return mapPmLink(rs);
            }
        }
    }

    private static SudzPmLink mapPmLink(ResultSet rs) throws SQLException {
        return new SudzPmLink(
                rs.getInt("g_p_key"),
                rs.getInt("cn_inv_dbt_upl"),
                rs.getInt("cn_inv_pm_upl"),
                rs.getString("cn_inv_pm_name"),
                getLocalDate(rs, "cn_inv_pm_date"),
                rs.getString("upl_name"),
                getLocalDate(rs, "upl_date")
        );
    }

    private int insertUpl(Connection connection, String name, LocalDate uplDate, LocalDate statusOnDate)
            throws SQLException {
        int nextKey;
        String nextSql = "SELECT ISNULL(MAX(upl_key), 0) + 1 FROM " + q("cn_inv_dbt_upl")
                + " WITH (UPDLOCK, HOLDLOCK)";
        try (PreparedStatement statement = connection.prepareStatement(nextSql);
             ResultSet rs = statement.executeQuery()) {
            rs.next();
            nextKey = rs.getInt(1);
        }
        String insert = "INSERT INTO " + q("cn_inv_dbt_upl")
                + " (upl_key, upl_date, uplStatusOnDate, upl_name) VALUES (?, ?, ?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(insert)) {
            statement.setInt(1, nextKey);
            if (uplDate == null) {
                statement.setNull(2, Types.TIMESTAMP);
            } else {
                statement.setDate(2, Date.valueOf(uplDate));
            }
            statement.setDate(3, Date.valueOf(statusOnDate));
            statement.setString(4, name);
            statement.executeUpdate();
        }
        return nextKey;
    }

    private int insertYearUplIfAbsent(Connection connection, int yrKey, int uplKey) throws SQLException {
        String find = "SELECT yr_upl_p_key FROM " + q("yr_upl_p")
                + " WHERE yr_upl_p_yr = ? AND cn_inv_dbt_upl = ?";
        try (PreparedStatement statement = connection.prepareStatement(find)) {
            statement.setInt(1, yrKey);
            statement.setInt(2, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        String insert = "INSERT INTO " + q("yr_upl_p") + " (yr_upl_p_yr, cn_inv_dbt_upl) VALUES (?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, yrKey);
            statement.setInt(2, uplKey);
            statement.executeUpdate();
            return readGeneratedKey(statement, "Не удалось получить yr_upl_p_key");
        }
    }

    private Integer findPmLinkKey(Connection connection, int dbtUplKey, int pmKey) throws SQLException {
        String sql = "SELECT [key] FROM " + q("cn_inv_dbt_upl_g_p")
                + " WHERE cn_inv_dbt_upl = ? AND cn_inv_pm_upl = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, dbtUplKey);
            statement.setInt(2, pmKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
                return null;
            }
        }
    }

    private void ensureUplExists(Connection connection, int uplKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("cn_inv_dbt_upl") + " WHERE upl_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, uplKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Выгрузка ДЗ не найдена: uplKey=" + uplKey);
                }
            }
        }
    }

    private void ensurePmExists(Connection connection, int pmKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("cn_inv_pm_upl") + " WHERE cn_inv_pm_key = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, pmKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Выгрузка платежей не найдена: pmKey=" + pmKey);
                }
            }
        }
    }

    private void ensureYyyyExists(Connection connection, int yKey) throws SQLException {
        String sql = "SELECT 1 FROM ags.yyyy WHERE yKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, yKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Календарный год не найден в ags.yyyy: yKey=" + yKey);
                }
            }
        }
    }

    private void ensureCmmGrExists(Connection connection, int cmmGrKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("cnInvCmmGr") + " WHERE cnicgKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cmmGrKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Группа комментариев не найдена: cmmGrKey=" + cmmGrKey);
                }
            }
        }
    }

    private static int readGeneratedKey(PreparedStatement statement, String errorMessage)
            throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (keys.next()) {
                return keys.getInt(1);
            }
        }
        throw new DaoException(errorMessage);
    }

    private void upsertComment(
            Connection connection,
            int cmmGr,
            int dbtKey,
            int cnicType,
            String text
    ) throws SQLException {
        if (text == null) {
            String deleteSql = "DELETE FROM " + q("cnInvCmm")
                    + " WHERE cnicGroup = ? AND cnicInvAccnt = ? AND cnicType = ?";
            try (PreparedStatement statement = connection.prepareStatement(deleteSql)) {
                statement.setInt(1, cmmGr);
                statement.setInt(2, dbtKey);
                statement.setInt(3, cnicType);
                statement.executeUpdate();
            }
            return;
        }

        String updateSql = "UPDATE " + q("cnInvCmm")
                + " SET cnicText = ? WHERE cnicGroup = ? AND cnicInvAccnt = ? AND cnicType = ?";
        try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
            statement.setString(1, text);
            statement.setInt(2, cmmGr);
            statement.setInt(3, dbtKey);
            statement.setInt(4, cnicType);
            int updated = statement.executeUpdate();
            if (updated > 0) {
                return;
            }
        }

        String insertSql = "INSERT INTO " + q("cnInvCmm")
                + " (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt) VALUES (?, ?, NULL, ?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
            statement.setInt(1, cnicType);
            statement.setInt(2, cmmGr);
            statement.setString(3, text);
            statement.setInt(4, dbtKey);
            statement.executeUpdate();
        }
    }

    private String upsertCst(Connection connection, int cmmGr, int dbtKey, String cstCode)
            throws SQLException {
        if (cstCode == null) {
            String deleteSql = "DELETE FROM " + q("cnInvCmmCst")
                    + " WHERE ciccCmmGr = ? AND ciccInvAccnt = ? AND ciccType = ?";
            try (PreparedStatement statement = connection.prepareStatement(deleteSql)) {
                statement.setInt(1, cmmGr);
                statement.setInt(2, dbtKey);
                statement.setInt(3, CICC_TYPE_CST);
                statement.executeUpdate();
            }
            return null;
        }

        Integer cstapKey;
        String cstName;
        String lookupSql = "SELECT TOP (1) pn.cstapKey, cst.cstName "
                + "FROM ags.cstAgPn pn "
                + "JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta "
                + "JOIN ags.cst cst ON cst.cstKey = ca.cstaCst "
                + "WHERE pn.cstapIpgPnN = ? "
                + "ORDER BY pn.cstapKey";
        try (PreparedStatement statement = connection.prepareStatement(lookupSql)) {
            statement.setString(1, cstCode);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Код стройки не найден в ags.cstAgPn: " + cstCode);
                }
                cstapKey = rs.getInt("cstapKey");
                cstName = rs.getString("cstName");
            }
        }

        String updateSql = "UPDATE " + q("cnInvCmmCst")
                + " SET ciccCstAgPn = ? WHERE ciccCmmGr = ? AND ciccInvAccnt = ? AND ciccType = ?";
        try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
            statement.setInt(1, cstapKey);
            statement.setInt(2, cmmGr);
            statement.setInt(3, dbtKey);
            statement.setInt(4, CICC_TYPE_CST);
            int updated = statement.executeUpdate();
            if (updated > 0) {
                return cstName;
            }
        }

        String insertSql = "INSERT INTO " + q("cnInvCmmCst")
                + " (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt) VALUES (?, ?, ?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
            statement.setInt(1, cmmGr);
            statement.setInt(2, CICC_TYPE_CST);
            statement.setInt(3, cstapKey);
            statement.setInt(4, dbtKey);
            statement.executeUpdate();
        }
        return cstName;
    }

    private static String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static ResultSet firstResultSet(CallableStatement statement) throws SQLException {
        boolean hasResult = statement.execute();
        while (!hasResult && statement.getUpdateCount() != -1) {
            hasResult = statement.getMoreResults();
        }
        return hasResult ? statement.getResultSet() : null;
    }

    private static SudzYear mapYear(ResultSet rs) throws SQLException {
        return new SudzYear(
                rs.getInt("yr_key"),
                rs.getString("yr_variant"),
                getInteger(rs, "cn_inv_dbt_upl"),
                getInteger(rs, "yyyy"),
                getInteger(rs, "yr_CmmGr"),
                rs.getString("base_upl_name"),
                getLocalDate(rs, "base_upl_date"),
                rs.getString("cmm_gr_name"),
                getLocalDate(rs, "cmm_gr_date"),
                getInteger(rs, "yr_CmmGr_New"),
                rs.getString("cmm_gr_new_name"),
                getLocalDate(rs, "cmm_gr_new_date"),
                getInteger(rs, "yyyy_value"),
                rs.getString("yr_Progress")
        );
    }

    private static SudzD644Row mapD644(ResultSet rs) throws SQLException {
        return new SudzD644Row(
                rs.getInt("dbtKey"),
                getInteger(rs, "Счёт Главной книги"),
                rs.getString("Агент"),
                getLong(rs, "№ контрагента"),
                rs.getString("ИНН контрагента"),
                rs.getString("Контрагент"),
                rs.getString("Договор"),
                getLocalDate(rs, "Дата договора"),
                rs.getString("счет-фактура"),
                getLocalDate(rs, "Дата образования"),
                getLocalDate(rs, "Срок погашения base"),
                getBigDecimal(rs, "Всего сумма задолженности base"),
                getBigDecimal(rs, "Просроченная задолженность base"),
                getLocalDate(rs, "Срок погашения curr"),
                getBigDecimal(rs, "Просроченная задолженность curr"),
                getBigDecimal(rs, "Погашено проср задолженности с начала года"),
                rs.getString("Код стройки"),
                rs.getString("Наименование стройки"),
                rs.getString("Комментарий Филиала 644"),
                getLocalDate(rs, "_base_upl_date"),
                getLocalDate(rs, "_curr_upl_date"),
                getInteger(rs, "_base_upl"),
                getInteger(rs, "_curr_upl")
        );
    }

    private static Integer getInteger(ResultSet rs, String column) throws SQLException {
        int value = rs.getInt(column);
        return rs.wasNull() ? null : value;
    }

    private static Long getLong(ResultSet rs, String column) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private static Double getDouble(ResultSet rs, String column) throws SQLException {
        double value = rs.getDouble(column);
        return rs.wasNull() ? null : value;
    }

    private static BigDecimal getBigDecimal(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return rs.wasNull() ? null : value;
    }

    private static LocalDate getLocalDate(ResultSet rs, String column) throws SQLException {
        Date value = rs.getDate(column);
        return value == null ? null : value.toLocalDate();
    }

    private DaoException wrap(String message, SQLException exception) {
        log.log(Level.SEVERE, message, exception);
        return new DaoException(message, exception);
    }

    private static final class Builder {
        private final int dbtKey;
        private final String accountNum;
        private final String curator;
        private final String mery;
        private final String cstCode;
        private final String cstName;
        private final String curatorNew;
        private final String meryNew;
        private final String cstCodeNew;
        private final List<SudzRsltPeriod> periods = new ArrayList<>();
        private BigDecimal baseOverd;

        private Builder(int dbtKey, String accountNum, String curator, String mery,
                        String cstCode, String cstName,
                        String curatorNew, String meryNew, String cstCodeNew) {
            this.dbtKey = dbtKey;
            this.accountNum = accountNum;
            this.curator = curator;
            this.mery = mery;
            this.cstCode = cstCode;
            this.cstName = cstName;
            this.curatorNew = curatorNew;
            this.meryNew = meryNew;
            this.cstCodeNew = cstCodeNew;
        }

        private SudzRsltDebt buildCollapsed() {
            return new SudzRsltDebt(dbtKey, accountNum, curator, mery, cstCode, cstName,
                    curatorNew, meryNew, cstCodeNew, collapseRsltPeriods(periods));
        }
    }

    /**
     * Схлопывает несколько {@code vw_Yr_DbtFact}-строк одного {@code dbtKey} на один {@code uplKey}
     * (L*: два слота → один долг). Для базового upl — «левый» СF (А19…); для последующих — continuator (90, 7…).
     */
    private static List<SudzRsltPeriod> collapseRsltPeriods(List<SudzRsltPeriod> rows) {
        if (rows.size() <= 1) {
            return List.copyOf(rows);
        }
        Map<Integer, List<SudzRsltPeriod>> byUpl = new LinkedHashMap<>();
        for (SudzRsltPeriod row : rows) {
            byUpl.computeIfAbsent(row.uplKey(), key -> new ArrayList<>()).add(row);
        }
        int minUpl = byUpl.keySet().stream().min(Integer::compareTo).orElse(0);
        List<SudzRsltPeriod> merged = new ArrayList<>(byUpl.size());
        for (Map.Entry<Integer, List<SudzRsltPeriod>> entry : byUpl.entrySet()) {
            merged.add(mergeRsltPeriodSlice(entry.getValue(), entry.getKey() == minUpl));
        }
        merged.sort(Comparator
                .comparing(SudzRsltPeriod::uplDate, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(SudzRsltPeriod::uplKey));
        return List.copyOf(merged);
    }

    private static SudzRsltPeriod mergeRsltPeriodSlice(List<SudzRsltPeriod> slice, boolean baseUpl) {
        if (slice.size() == 1) {
            return slice.get(0);
        }
        String invPick = pickMergedInvNumEnum(slice, baseUpl);
        SudzRsltPeriod template = slice.stream()
                .filter(p -> invPick != null && invPick.equals(p.invNumEnum()))
                .findFirst()
                .orElse(slice.get(0));
        if (invPick == null || invPick.equals(template.invNumEnum())) {
            return template;
        }
        return new SudzRsltPeriod(
                template.uplKey(), template.uplDate(), template.asOf(), invPick,
                template.idNum(), template.cnNumEnum(), template.csoCnDate(),
                template.orgIdValueL(), template.itn(), template.ctptOrg(),
                template.maturity(), template.ttl(), template.overd(),
                template.cstAgPnCode(), template.cstAgPnName(), template.agOrg(),
                template.pogasheno()
        );
    }

    private static String pickMergedInvNumEnum(List<SudzRsltPeriod> slice, boolean baseUpl) {
        List<String> distinct = slice.stream()
                .map(SudzRsltPeriod::invNumEnum)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        if (distinct.size() <= 1) {
            return distinct.isEmpty() ? null : distinct.get(0);
        }
        if (baseUpl) {
            Optional<String> left = distinct.stream()
                    .filter(n -> n.startsWith("А19"))
                    .findFirst();
            if (left.isPresent()) {
                return left.get();
            }
        } else {
            Optional<String> cont = distinct.stream()
                    .filter(n -> !n.startsWith("А19"))
                    .findFirst();
            if (cont.isPresent()) {
                return cont.get();
            }
        }
        return distinct.get(0);
    }

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }
}
