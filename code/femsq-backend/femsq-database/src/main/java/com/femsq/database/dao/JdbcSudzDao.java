package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.sudz.SudzCmmGrLookup;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzPmLink;
import com.femsq.database.model.sudz.SudzPmUplLookup;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
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
import java.sql.Types;
import java.time.LocalDate;
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
    public void updateYear(int yrKey, String variant, int baseUplKey, int yKey, Integer cmmGrKey) {
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

                // yr_Progress намеренно не обновляем
                String sql = "UPDATE " + q("yr")
                        + " SET yr_variant = ?, cn_inv_dbt_upl = ?, yyyy = ?, yr_CmmGr = ?"
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
                    statement.setInt(5, yrKey);
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
    public String appendYearProgress(int yrKey, String line) {
        log.log(Level.INFO, "Appending yr_Progress yr={0}", yrKey);
        String sql = "UPDATE " + q("yr")
                + " SET yr_Progress = CASE"
                + "   WHEN yr_Progress IS NULL OR LTRIM(RTRIM(yr_Progress)) = N'' THEN ?"
                + "   ELSE yr_Progress + CHAR(13) + CHAR(10) + ?"
                + " END"
                + " WHERE yr_key = ?";
        String readSql = "SELECT yr_Progress FROM " + q("yr") + " WHERE yr_key = ?";
        try (Connection connection = connectionFactory.createConnection()) {
            if (findYearOn(connection, yrKey).isEmpty()) {
                throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
            }
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setString(1, line);
                statement.setString(2, line);
                statement.setInt(3, yrKey);
                statement.executeUpdate();
            }
            try (PreparedStatement statement = connection.prepareStatement(readSql)) {
                statement.setInt(1, yrKey);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Год-вариант СУДЗ не найден: yr=" + yrKey);
                    }
                    String progress = rs.getString(1);
                    return progress == null ? "" : progress;
                }
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw wrap("Не удалось дописать yr_Progress yr=" + yrKey, exception);
        }
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
                + "       cy.cst_code, cy.cst_name "
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
            if (asOfUpl == null) {
                statement.setNull(4, Types.INTEGER);
                statement.setNull(5, Types.INTEGER);
            } else {
                statement.setInt(4, asOfUpl);
                statement.setInt(5, asOfUpl);
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
                                rs.getString("cst_name")
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

    private String yearSelectSql() {
        return "SELECT y.yr_key, y.yr_variant, y.cn_inv_dbt_upl, y.yyyy, y.yr_CmmGr, y.yr_Progress, "
                + "u.upl_name AS base_upl_name, u.upl_date AS base_upl_date, "
                + "g.cnicgName AS cmm_gr_name, g.cnicgDate AS cmm_gr_date, "
                + "yy.yyyy AS yyyy_value "
                + "FROM " + q("yr") + " y "
                + "LEFT JOIN " + q("cn_inv_dbt_upl") + " u ON u.upl_key = y.cn_inv_dbt_upl "
                + "LEFT JOIN " + q("cnInvCmmGr") + " g ON g.cnicgKey = y.yr_CmmGr "
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
        private final List<SudzRsltPeriod> periods = new ArrayList<>();
        private BigDecimal baseOverd;

        private Builder(int dbtKey, String accountNum, String curator, String mery,
                        String cstCode, String cstName) {
            this.dbtKey = dbtKey;
            this.accountNum = accountNum;
            this.curator = curator;
            this.mery = mery;
            this.cstCode = cstCode;
            this.cstName = cstName;
        }

        private SudzRsltDebt build() {
            return new SudzRsltDebt(dbtKey, accountNum, curator, mery, cstCode, cstName,
                    List.copyOf(periods));
        }
    }
}
