package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDbtUplFile;
import com.femsq.database.model.sudz.SudzDbtUplFileSh;
import com.femsq.database.model.sudz.SudzDbtUplInvDouble;
import com.femsq.database.model.sudz.SudzDbtUplLauncher;
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
                    BigDecimal pogasheno = null;
                    if (builder.baseOverd != null && overd != null
                            && builder.baseOverd.compareTo(overd) != 0) {
                        BigDecimal delta = builder.baseOverd.subtract(overd);
                        if (delta.compareTo(BigDecimal.ZERO) != 0) {
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
                    debts.add(builder.build());
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
            if (file.isPresent()) {
                int fileKey = file.get().cidufKey();
                sheets = loadDbtUplFileSheets(connection, fileKey);
                invDoubles = loadDbtUplInvDoubles(connection, fileKey);
            }
            sfDoubles = loadSfDoublesByUnload(connection, uplKey);
            return Optional.of(new SudzDbtUplLauncher(
                    upl.get(), file.orElse(null), sheets, invDoubles, sfDoubles));
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
                        + "  SELECT ci.ciCn AS cn_key, n.inNumNull "
                        + "  FROM ags.cnInv AS ci "
                        + "  INNER JOIN #ciduMatched AS m ON m.cn_key = ci.ciCn "
                        + "  INNER JOIN ags.invNum AS n ON n.inInv = ci.ciInv "
                        + "  GROUP BY ci.ciCn, n.inNumNull"
                        + ") AS g ON g.cn_key = p.cn_key AND g.inNumNull = p.cidutCnInvNull "
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
                try (PreparedStatement statement = connection.prepareStatement(select);
                     ResultSet rs = statement.executeQuery()) {
                    while (rs.next()) {
                        int cnKey = rs.getInt("cidutciCn_key");
                        String cnInv = rs.getNString("cidutciCnInv");
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
                log.log(Level.INFO, "applyDbtUplCnCtptExistInvNotLoad unloadKey={0} inserted={1}",
                        new Object[]{unloadKey, inserted});
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
        String sql = "SELECT cidufsKey, cidufsFile, cidufsSheet, cidufsAccount, cidufsTest"
                + " FROM " + q("CnInvDbtUplFileSh")
                + " WHERE cidufsFile = ? ORDER BY cidufsKey";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<SudzDbtUplFileSh> result = new ArrayList<>();
                while (rs.next()) {
                    result.add(new SudzDbtUplFileSh(
                            rs.getInt("cidufsKey"),
                            rs.getInt("cidufsFile"),
                            rs.getString("cidufsSheet"),
                            rs.getInt("cidufsAccount"),
                            rs.getBoolean("cidufsTest")
                    ));
                }
                return List.copyOf(result);
            }
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
                + "SELECT t.cidutKey, t.FindDbtNum, t.cidutAccount, t.cidutCntrPrtNum,"
                + " t.cidutCntrPrtName, t.cidutCntrPrtITN, t.cidutCnName, t.cidutCnDate,"
                + " t.cidutCnInv, t.cidutCnInvName, t.cidutFormtnDate, t.cidutMatrtyDate,"
                + " t.cidutDebt, t.cidutDebtOverdue, t.cidutDoc, t.cidutLink,"
                + " t.cidutSheet, t.cidutSheetNum, t.cidutUnloadKey"
                + " FROM " + q("CnInvUplSfDouble") + " AS q"
                + " INNER JOIN " + q("CnInvDbtUplTbl") + " AS t ON t.cidutKey = q.ciusCidut"
                + " WHERE q.ciusKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ciusKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(new SudzSfDoubleExcelCandidate(
                        rs.getInt("cidutKey"),
                        getInteger(rs, "FindDbtNum"),
                        getInteger(rs, "cidutAccount"),
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
                ));
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

    private static java.time.LocalDate toLocalDate(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime().toLocalDate();
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

        private SudzRsltDebt build() {
            return new SudzRsltDebt(dbtKey, accountNum, curator, mery, cstCode, cstName,
                    curatorNew, meryNew, cstCodeNew, List.copyOf(periods));
        }
    }

    private static Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }
}
