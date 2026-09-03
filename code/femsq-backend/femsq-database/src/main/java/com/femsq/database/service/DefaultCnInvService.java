package com.femsq.database.service;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnInv;
import com.femsq.database.model.CnInvListItem;
import com.femsq.database.model.CnInvPage;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Доменный сервис {@code ags.cnInv}: CRUD связи и page-список по договору.
 */
public class DefaultCnInvService implements CnInvService {

    private static final Logger log = Logger.getLogger(DefaultCnInvService.class.getName());
    private static final int DEFAULT_ROWS = 25;
    private static final int MAX_ROWS = 200;
    private static final Set<String> SORT_WHITELIST = Set.of("ciKey", "ciInv", "iNum", "ciTimeOfEntry");

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public DefaultCnInvService(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService
    ) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    @Override
    public CnInvPage listByCn(
            int cnKey,
            int page,
            int rowsPerPage,
            String filter,
            String sortBy,
            boolean descending
    ) {
        requirePositive("cnKey", cnKey);
        int safePage = page < 1 ? 1 : page;
        int safeRows = rowsPerPage < 1 ? DEFAULT_ROWS : Math.min(rowsPerPage, MAX_ROWS);
        int offset = (safePage - 1) * safeRows;
        String orderCol = resolveSortColumn(sortBy);
        String orderDir = descending ? "DESC" : "ASC";
        String schema = schemaPrefix();
        String trimmedFilter = filter == null ? "" : filter.trim();
        Integer numericFilter = parsePositiveInt(trimmedFilter);

        String fromJoin = " FROM " + schema + "cnInv ci LEFT JOIN " + schema + "inv i ON i.iKey = ci.ciInv"
                + " WHERE ci.ciCn = ?";
        StringBuilder whereExtra = new StringBuilder();
        List<Object> filterParams = new ArrayList<>();
        if (!trimmedFilter.isEmpty()) {
            whereExtra.append(" AND (LOWER(CAST(i.iNum AS nvarchar(200))) LIKE ?");
            filterParams.add("%" + trimmedFilter.toLowerCase(Locale.ROOT) + "%");
            if (numericFilter != null) {
                whereExtra.append(" OR ci.ciInv = ? OR ci.ciKey = ?");
                filterParams.add(numericFilter);
                filterParams.add(numericFilter);
            }
            whereExtra.append(')');
        }

        String countSql = "SELECT COUNT(*)" + fromJoin + whereExtra;
        String dataSql = "SELECT ci.ciKey, ci.ciInv, ci.ciCn, ci.ciTimeOfEntry, i.iNum"
                + fromJoin + whereExtra
                + " ORDER BY " + orderCol + ' ' + orderDir
                + " OFFSET " + offset + " ROWS FETCH NEXT " + safeRows + " ROWS ONLY";

        try (Connection connection = connectionFactory.createConnection()) {
            int total = executeCount(connection, countSql, cnKey, filterParams);
            List<CnInvListItem> items = executePage(connection, dataSql, cnKey, filterParams);
            log.log(Level.FINE, "CnInvService.listByCn cnKey={0} page={1} rows={2} total={3}",
                    new Object[]{cnKey, safePage, safeRows, total});
            return new CnInvPage(List.copyOf(items), total, safePage, safeRows);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось загрузить cnInv page для cn=" + cnKey, exception);
        }
    }

    @Override
    public CnInv create(int invKey, int cnKey) {
        requirePositive("invKey", invKey);
        requirePositive("cnKey", cnKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                requireExists(connection, "SELECT 1 FROM " + schema + "inv WHERE iKey = ?", "СФ inv не найден: ", invKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "cn WHERE cn_key = ?", "Договор cn не найден: ", cnKey);
                CnInv existing = findByPair(connection, schema, invKey, cnKey);
                if (existing != null) {
                    connection.commit();
                    return existing;
                }
                Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                int ciKey;
                try (PreparedStatement statement = connection.prepareStatement(
                        "INSERT INTO " + schema + "cnInv (ciInv, ciCn, ciTimeOfEntry) VALUES (?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, invKey);
                    statement.setInt(2, cnKey);
                    statement.setTimestamp(3, now);
                    statement.executeUpdate();
                    try (ResultSet rs = statement.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new DaoException("Не удалось получить ciKey после INSERT cnInv");
                        }
                        ciKey = rs.getInt(1);
                    }
                }
                CnInv created = findById(connection, schema, ciKey);
                connection.commit();
                log.log(Level.INFO, "CnInvService.create ciKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciKey, invKey, cnKey});
                return created;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать cnInv для inv=" + invKey + ", cn=" + cnKey, exception);
        }
    }

    @Override
    public CnInv update(int ciKey, int invKey, int cnKey) {
        requirePositive("ciKey", ciKey);
        requirePositive("invKey", invKey);
        requirePositive("cnKey", cnKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                CnInv current = findById(connection, schema, ciKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "inv WHERE iKey = ?", "СФ inv не найден: ", invKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "cn WHERE cn_key = ?", "Договор cn не найден: ", cnKey);
                if (current.ciInv() == invKey && current.ciCn() == cnKey) {
                    connection.commit();
                    return current;
                }
                CnInv duplicate = findByPair(connection, schema, invKey, cnKey);
                if (duplicate != null && !Objects.equals(duplicate.ciKey(), ciKey)) {
                    throw new IllegalArgumentException(
                            "Связь cnInv уже существует: ciKey=" + duplicate.ciKey() + " (inv=" + invKey + ", cn=" + cnKey + ")");
                }
                int oldCnKey = current.ciCn();
                int oldInvKey = current.ciInv();
                try (PreparedStatement statement = connection.prepareStatement(
                        "UPDATE " + schema + "cnInv SET ciInv = ?, ciCn = ? WHERE ciKey = ?")) {
                    statement.setInt(1, invKey);
                    statement.setInt(2, cnKey);
                    statement.setInt(3, ciKey);
                    int affected = statement.executeUpdate();
                    if (affected == 0) {
                        throw new DaoException("Не удалось обновить cnInv ciKey=" + ciKey);
                    }
                }
                if (oldCnKey != cnKey) {
                    remappingInvDbtVarForCnTransfer(connection, schema, oldInvKey, oldCnKey, cnKey);
                }
                CnInv updated = findById(connection, schema, ciKey);
                connection.commit();
                log.log(Level.INFO, "CnInvService.update ciKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciKey, invKey, cnKey});
                return updated;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить cnInv ciKey=" + ciKey, exception);
        }
    }

    @Override
    public boolean delete(int ciKey) {
        requirePositive("ciKey", ciKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "DELETE FROM " + schema + "cnInv WHERE ciKey = ?")) {
            statement.setInt(1, ciKey);
            boolean deleted = statement.executeUpdate() > 0;
            log.log(Level.INFO, "CnInvService.delete ciKey={0} deleted={1}", new Object[]{ciKey, deleted});
            return deleted;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить cnInv ciKey=" + ciKey, exception);
        }
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                return "ags.";
            }
            return schema.trim() + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration missing for cnInv, fallback ags.", exception);
            return "ags.";
        }
    }

    /**
     * При переносе cnInv на другой договор перепривязывает контекст {@code sudz.invDbtVar}
     * (чётвёрка cnNum/invNum/accnt/cn_s_org), чтобы не рвать мост {@code invDbtDbtVar}.
     *
     * @param connection открытая транзакция
     * @param schema префикс ags (с точкой)
     * @param invKey СФ (до/после переноса — тот же iKey, если inv не меняли)
     * @param oldCnKey исходный договор
     * @param newCnKey целевой договор
     */
    private void remappingInvDbtVarForCnTransfer(
            Connection connection,
            String schema,
            int invKey,
            int oldCnKey,
            int newCnKey
    ) throws SQLException {
        if (oldCnKey == newCnKey) {
            return;
        }
        String selectVars = ""
                + "SELECT v.idvvKey, v.idvvCnNum, v.idvvInvNum, v.idvvAccnt, v.idvvCn_s_org "
                + "FROM sudz.invDbtVar AS v "
                + "WHERE v.idvvInvNum IN (SELECT n.inKey FROM " + schema + "invNum AS n WHERE n.inInv = ?) "
                + "  AND ( "
                + "    v.idvvCn_s_org IN ("
                + "      SELECT o.cn_s_org_key FROM " + schema + "cn_s_org AS o "
                + "      INNER JOIN " + schema + "cn_s_org_smpl AS m ON m.csosKey = o.csoCn_s_org_smpl "
                + "      INNER JOIN " + schema + "cn_s AS s ON s.cn_s_key = m.csosCn_s "
                + "      WHERE s.cn_key = ?) "
                + "    OR v.idvvCnNum IN (SELECT cnnKey FROM " + schema + "cnNum WHERE cnnCn = ?) "
                + "  )";
        List<int[]> vars = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(selectVars)) {
            statement.setInt(1, invKey);
            statement.setInt(2, oldCnKey);
            statement.setInt(3, oldCnKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    vars.add(new int[]{
                            rs.getInt("idvvKey"),
                            rs.getInt("idvvCnNum"),
                            rs.getInt("idvvInvNum"),
                            rs.getInt("idvvAccnt"),
                            rs.getInt("idvvCn_s_org")
                    });
                }
            }
        }
        for (int[] var : vars) {
            int idvvKey = var[0];
            int oldCnnKey = var[1];
            int invNumKey = var[2];
            int accntKey = var[3];
            int oldOrgKey = var[4];
            Integer targetCnn = resolveTargetCnNum(connection, schema, oldCnnKey, newCnKey);
            Integer targetOrg = resolveTargetCnSOrg(connection, schema, oldOrgKey, newCnKey);
            if (targetCnn == null || targetOrg == null) {
                throw new IllegalArgumentException(
                        "Не удалось перепривязать invDbtVar idvvKey=" + idvvKey
                                + ": на cn=" + newCnKey + " нет подходящего cnNum/cn_s_org "
                                + "(сначала добавьте номер и сторону на целевом договоре).");
            }
            Integer existing = findInvDbtVarKey(connection, targetCnn, invNumKey, accntKey, targetOrg);
            if (existing != null && existing == idvvKey) {
                continue;
            }
            if (existing != null) {
                mergeInvDbtVarBridge(connection, idvvKey, existing);
                try (PreparedStatement del = connection.prepareStatement(
                        "DELETE FROM sudz.invDbtVar WHERE idvvKey = ?")) {
                    del.setInt(1, idvvKey);
                    del.executeUpdate();
                }
                log.log(Level.INFO,
                        "Merged invDbtVar idvvKey={0} → {1} (cn {2}→{3})",
                        new Object[]{idvvKey, existing, oldCnKey, newCnKey});
            } else {
                try (PreparedStatement upd = connection.prepareStatement(
                        "UPDATE sudz.invDbtVar SET idvvCnNum = ?, idvvCn_s_org = ? WHERE idvvKey = ?")) {
                    upd.setInt(1, targetCnn);
                    upd.setInt(2, targetOrg);
                    upd.setInt(3, idvvKey);
                    upd.executeUpdate();
                }
                log.log(Level.INFO,
                        "Remapped invDbtVar idvvKey={0}: cnNum {1}→{2}, cn_s_org {3}→{4} (cn {5}→{6})",
                        new Object[]{idvvKey, oldCnnKey, targetCnn, oldOrgKey, targetOrg, oldCnKey, newCnKey});
            }
        }
    }

    private static Integer resolveTargetCnNum(
            Connection connection,
            String schema,
            int oldCnnKey,
            int newCnKey
    ) throws SQLException {
        String oldNum = null;
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT cnnNum FROM " + schema + "cnNum WHERE cnnKey = ?")) {
            statement.setInt(1, oldCnnKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    oldNum = rs.getNString(1);
                }
            }
        }
        if (oldNum != null && !oldNum.isBlank()) {
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT TOP 1 cnnKey FROM " + schema + "cnNum "
                            + "WHERE cnnCn = ? AND LTRIM(RTRIM(cnnNum)) = LTRIM(RTRIM(?)) "
                            + "ORDER BY cnnKey")) {
                statement.setInt(1, newCnKey);
                statement.setNString(2, oldNum.trim());
                try (ResultSet rs = statement.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
        }
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT TOP 1 cnnKey FROM " + schema + "cnNum WHERE cnnCn = ? ORDER BY cnnKey")) {
            statement.setInt(1, newCnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    private static Integer resolveTargetCnSOrg(
            Connection connection,
            String schema,
            int oldOrgKey,
            int newCnKey
    ) throws SQLException {
        Integer orgId = null;
        java.sql.Date cnDate = null;
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT m.csosOrgId, o.csoCnDate FROM " + schema + "cn_s_org AS o "
                        + "INNER JOIN " + schema + "cn_s_org_smpl AS m ON m.csosKey = o.csoCn_s_org_smpl "
                        + "WHERE o.cn_s_org_key = ?")) {
            statement.setInt(1, oldOrgKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    orgId = (Integer) rs.getObject(1);
                    cnDate = rs.getDate(2);
                }
            }
        }
        String base = ""
                + "SELECT TOP 1 o.cn_s_org_key FROM " + schema + "cn_s_org AS o "
                + "INNER JOIN " + schema + "cn_s_org_smpl AS m ON m.csosKey = o.csoCn_s_org_smpl "
                + "INNER JOIN " + schema + "cn_s AS s ON s.cn_s_key = m.csosCn_s "
                + "WHERE s.cn_key = ? AND s.cn_s_type = 2 ";
        if (orgId != null && cnDate != null) {
            try (PreparedStatement statement = connection.prepareStatement(
                    base + "AND m.csosOrgId = ? AND o.csoCnDate = ? ORDER BY o.cn_s_org_key")) {
                statement.setInt(1, newCnKey);
                statement.setInt(2, orgId);
                statement.setDate(3, cnDate);
                try (ResultSet rs = statement.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
        }
        if (orgId != null) {
            try (PreparedStatement statement = connection.prepareStatement(
                    base + "AND m.csosOrgId = ? ORDER BY "
                            + "CASE WHEN o.csoCnDate IS NULL THEN 1 ELSE 0 END, o.cn_s_org_key")) {
                statement.setInt(1, newCnKey);
                statement.setInt(2, orgId);
                try (ResultSet rs = statement.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
        }
        try (PreparedStatement statement = connection.prepareStatement(
                base + "ORDER BY o.cn_s_org_key")) {
            statement.setInt(1, newCnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    private static Integer findInvDbtVarKey(
            Connection connection,
            int cnnKey,
            int invNumKey,
            int accntKey,
            int cnSOrgKey
    ) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT idvvKey FROM sudz.invDbtVar "
                        + "WHERE idvvCnNum = ? AND idvvInvNum = ? AND idvvAccnt = ? AND idvvCn_s_org = ?")) {
            statement.setInt(1, cnnKey);
            statement.setInt(2, invNumKey);
            statement.setInt(3, accntKey);
            statement.setInt(4, cnSOrgKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    private static void mergeInvDbtVarBridge(Connection connection, int fromVarKey, int toVarKey)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE sudz.invDbtDbtVar SET iddvInvDbtVar = ? "
                        + "WHERE iddvInvDbtVar = ? "
                        + "  AND NOT EXISTS ("
                        + "    SELECT 1 FROM sudz.invDbtDbtVar AS x "
                        + "    WHERE x.iddvInvDbt = sudz.invDbtDbtVar.iddvInvDbt "
                        + "      AND x.iddvInvDbtVar = ?)")) {
            statement.setInt(1, toVarKey);
            statement.setInt(2, fromVarKey);
            statement.setInt(3, toVarKey);
            statement.executeUpdate();
        }
        try (PreparedStatement statement = connection.prepareStatement(
                "DELETE FROM sudz.invDbtDbtVar WHERE iddvInvDbtVar = ?")) {
            statement.setInt(1, fromVarKey);
            statement.executeUpdate();
        }
    }

    private static void requireExists(Connection connection, String sql, String message, int key) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, key);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(message + key);
                }
            }
        }
    }

    private static void requirePositive(String label, int key) {
        if (key <= 0) {
            throw new IllegalArgumentException(label + " должен быть положительным: " + key);
        }
    }

    private static CnInv findByPair(Connection connection, String schema, int invKey, int cnKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ciKey, ciInv, ciCn, ciTimeOfEntry FROM " + schema + "cnInv WHERE ciInv = ? AND ciCn = ?")) {
            statement.setInt(1, invKey);
            statement.setInt(2, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    private static CnInv findById(Connection connection, String schema, int ciKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ciKey, ciInv, ciCn, ciTimeOfEntry FROM " + schema + "cnInv WHERE ciKey = ?")) {
            statement.setInt(1, ciKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new DaoException("Не удалось перечитать cnInv ciKey=" + ciKey);
                }
                return mapRow(rs);
            }
        }
    }

    private static CnInv mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("ciTimeOfEntry");
        OffsetDateTime entered = ts == null
                ? null
                : ts.toLocalDateTime().atZone(ZoneId.systemDefault()).toOffsetDateTime();
        return new CnInv(
                rs.getInt("ciKey"),
                rs.getInt("ciInv"),
                rs.getInt("ciCn"),
                entered
        );
    }

    private static int executeCount(
            Connection connection,
            String sql,
            int cnKey,
            List<Object> filterParams
    ) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bindListParams(statement, cnKey, filterParams);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return 0;
                }
                return rs.getInt(1);
            }
        }
    }

    private static List<CnInvListItem> executePage(
            Connection connection,
            String sql,
            int cnKey,
            List<Object> filterParams
    ) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bindListParams(statement, cnKey, filterParams);
            try (ResultSet rs = statement.executeQuery()) {
                List<CnInvListItem> items = new ArrayList<>();
                while (rs.next()) {
                    items.add(mapListItem(rs));
                }
                return items;
            }
        }
    }

    private static void bindListParams(
            PreparedStatement statement,
            int cnKey,
            List<Object> filterParams
    ) throws SQLException {
        int index = 1;
        statement.setInt(index++, cnKey);
        for (Object param : filterParams) {
            if (param instanceof String value) {
                statement.setNString(index++, value);
            } else if (param instanceof Integer value) {
                statement.setInt(index++, value);
            } else {
                statement.setObject(index++, param);
            }
        }
    }

    private static CnInvListItem mapListItem(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("ciTimeOfEntry");
        OffsetDateTime entered = ts == null
                ? null
                : ts.toLocalDateTime().atZone(ZoneId.systemDefault()).toOffsetDateTime();
        String iNum = rs.getString("iNum");
        if (rs.wasNull()) {
            iNum = null;
        }
        return new CnInvListItem(
                rs.getInt("ciKey"),
                rs.getInt("ciInv"),
                rs.getInt("ciCn"),
                entered,
                iNum
        );
    }

    /**
     * Whitelist колонки ORDER BY (с префиксом таблицы).
     */
    private static String resolveSortColumn(String sortBy) {
        String key = sortBy == null || sortBy.isBlank() ? "ciKey" : sortBy.trim();
        if (!SORT_WHITELIST.contains(key)) {
            key = "ciKey";
        }
        return switch (key) {
            case "iNum" -> "i.iNum";
            case "ciInv" -> "ci.ciInv";
            case "ciTimeOfEntry" -> "ci.ciTimeOfEntry";
            default -> "ci.ciKey";
        };
    }

    private static Integer parsePositiveInt(String raw) {
        if (raw == null || raw.isEmpty()) {
            return null;
        }
        for (int i = 0; i < raw.length(); i++) {
            if (!Character.isDigit(raw.charAt(i))) {
                return null;
            }
        }
        try {
            int value = Integer.parseInt(raw);
            return value > 0 ? value : null;
        } catch (NumberFormatException exception) {
            return null;
        }
    }
}
