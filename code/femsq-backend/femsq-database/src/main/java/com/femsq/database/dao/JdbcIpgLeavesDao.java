package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgPnBulkDraft;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
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
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link IpgLeavesDao} (C2 §2.4.2).
 */
public class JdbcIpgLeavesDao implements IpgLeavesDao {

    private static final Logger log = Logger.getLogger(JdbcIpgLeavesDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcIpgLeavesDao(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schema() {
        try {
            String value = configurationService.loadConfig().schema();
            if (value == null || value.isBlank()) {
                return "ags";
            }
            return value.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Schema missing, default ags", exception);
            return "ags";
        }
    }

    private String q(String table) {
        return schema() + "." + table;
    }

    private static final String IPG_SELECT = ""
            + "SELECT i.ipgKey, i.ipgOg, og.ogNm, i.ipgNm, i.ipgYy, yy.yyyy AS yearNum, "
            + "  i.ipgNum, i.ipgStr, i.ipgEnd, i.ipgRepl, i.ipgStRlSh, n.stnName, i.ipgYyYear "
            + "FROM %s i "
            + "INNER JOIN %s og ON og.ogKey = i.ipgOg "
            + "INNER JOIN %s yy ON yy.yKey = i.ipgYy "
            + "LEFT JOIN %s n ON n.stnKey = i.ipgStRlSh ";

    private String ipgSelectSql() {
        return String.format(IPG_SELECT, q("ipg"), q("og"), q("yyyy"), q("stNet"));
    }

    @Override
    public Optional<IpgFull> findIpgByKey(int ipgKey) {
        String sql = ipgSelectSql() + "WHERE i.ipgKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapIpg(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать ipg=" + ipgKey, exception);
        }
    }

    @Override
    public List<IpgFull> findIpgs(Integer year, Integer ogKey, String nameContains) {
        StringBuilder sql = new StringBuilder(ipgSelectSql());
        sql.append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (year != null) {
            sql.append("AND yy.yyyy = ? ");
            params.add(year);
        }
        if (ogKey != null) {
            sql.append("AND i.ipgOg = ? ");
            params.add(ogKey);
        }
        if (nameContains != null && !nameContains.isBlank()) {
            sql.append("AND i.ipgNm LIKE ? ");
            params.add("%" + nameContains.trim() + "%");
        }
        sql.append("ORDER BY yy.yyyy DESC, i.ipgNum, i.ipgNm");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgFull> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(mapIpg(resultSet));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить список ipg", exception);
        }
    }

    @Override
    public IpgFull createIpg(
            int ipgOg,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear) {
        Objects.requireNonNull(ipgNm, "ipgNm");
        Objects.requireNonNull(ipgStr, "ipgStr");
        if (ipgNm.isBlank()) {
            throw new IllegalArgumentException("Наименование ИП пустое");
        }
        // ipgYyYear — computed ([ags].[fnYyyyYear]([ipgYy])); в INSERT не писать.
        String sql = "INSERT INTO " + q("ipg")
                + " (ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, ipgOg);
            statement.setNString(2, ipgNm.trim());
            statement.setInt(3, ipgYy);
            statement.setShort(4, ipgNum);
            statement.setDate(5, Date.valueOf(ipgStr));
            if (ipgEnd == null) {
                statement.setNull(6, Types.DATE);
            } else {
                statement.setDate(6, Date.valueOf(ipgEnd));
            }
            if (ipgRepl == null) {
                statement.setNull(7, Types.INTEGER);
            } else {
                statement.setInt(7, ipgRepl);
            }
            statement.setInt(8, ipgStRlSh);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "ipgKey");
            log.log(Level.INFO, "Created ipg {0}", key);
            return findIpgByKey(key).orElseThrow(() -> new DaoException("ipg исчез после INSERT: " + key));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать ipg", exception);
        }
    }

    @Override
    public IpgFull updateIpg(
            int ipgKey,
            String ipgNm,
            int ipgYy,
            short ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            int ipgStRlSh,
            Integer ipgYyYear) {
        Objects.requireNonNull(ipgNm, "ipgNm");
        Objects.requireNonNull(ipgStr, "ipgStr");
        if (ipgNm.isBlank()) {
            throw new IllegalArgumentException("Наименование ИП пустое");
        }
        // ipgYyYear — computed; год меняется через ipgYy.
        String sql = "UPDATE " + q("ipg")
                + " SET ipgNm=?, ipgYy=?, ipgNum=?, ipgStr=?, ipgEnd=?, ipgRepl=?, ipgStRlSh=? "
                + "WHERE ipgKey=?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, ipgNm.trim());
            statement.setInt(2, ipgYy);
            statement.setShort(3, ipgNum);
            statement.setDate(4, Date.valueOf(ipgStr));
            if (ipgEnd == null) {
                statement.setNull(5, Types.DATE);
            } else {
                statement.setDate(5, Date.valueOf(ipgEnd));
            }
            if (ipgRepl == null) {
                statement.setNull(6, Types.INTEGER);
            } else {
                statement.setInt(6, ipgRepl);
            }
            statement.setInt(7, ipgStRlSh);
            statement.setInt(8, ipgKey);
            if (statement.executeUpdate() == 0) {
                throw new DaoException("ipg не найден: " + ipgKey);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить ipg=" + ipgKey, exception);
        }
        return findIpgByKey(ipgKey).orElseThrow(() -> new DaoException("ipg исчез после UPDATE: " + ipgKey));
    }

    private static final String PN_SELECT = ""
            + "SELECT p.ipgpKey, p.ipgpIpg, p.ipgpNum, p.ipgpCstAgPn, c.cstapIpgPnN, "
            + "  c.cstapCstName, c.cstapOgName, "
            + "  p.ipgpSmTtl, p.ipgpSmWrk, p.ipgpSmEqu, p.ipgpSmOth, p.ipgpSmAgFee, "
            + "  p.ipgpCostAdjust, p.ipgpSmReserv, p.ipgpTskCms, p.ipgpSh, s.ipgsNm "
            + "FROM %s p "
            + "INNER JOIN %s c ON c.cstapKey = p.ipgpCstAgPn "
            + "INNER JOIN %s s ON s.ipgsKey = p.ipgpSh ";

    private String pnSelectSql() {
        return String.format(PN_SELECT, q("ipgPn"), q("cstAgPn"), q("ipgSh"));
    }

    @Override
    public Optional<IpgPn> findPnByKey(int ipgpKey) {
        String sql = pnSelectSql() + "WHERE p.ipgpKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgpKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapPn(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать ipgPn=" + ipgpKey, exception);
        }
    }

    @Override
    public List<IpgPn> findPnsByIpg(int ipgKey) {
        String sql = pnSelectSql() + "WHERE p.ipgpIpg = ? ORDER BY p.ipgpNum, p.ipgpKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgPn> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(mapPn(resultSet));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить пункты ipg=" + ipgKey, exception);
        }
    }

    @Override
    public IpgPn createPn(
            int ipgpIpg,
            Integer ipgpNum,
            int ipgpCstAgPn,
            int ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms) {
        ensureUniquePn(ipgpIpg, ipgpCstAgPn, ipgpSh, null);
        String sql = "INSERT INTO " + q("ipgPn")
                + " (ipgpIpg, ipgpNum, ipgpCstAgPn, ipgpSmTtl, ipgpSmWrk, ipgpSmEqu, ipgpSmOth, "
                + "  ipgpSmAgFee, ipgpCostAdjust, ipgpSmReserv, ipgpTskCms, ipgpSh) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindPnParams(
                    statement,
                    ipgpIpg,
                    ipgpNum,
                    ipgpCstAgPn,
                    ipgpSmTtl,
                    ipgpSmWrk,
                    ipgpSmEqu,
                    ipgpSmOth,
                    ipgpSmAgFee,
                    ipgpCostAdjust,
                    ipgpSmReserv,
                    ipgpTskCms,
                    ipgpSh);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "ipgpKey");
            seedIpgPnLim(connection, key, ipgpSmTtl, ipgpSmWrk, ipgpSmEqu, ipgpSmOth);
            log.log(Level.INFO, "Created ipgPn {0} for ipg {1}", new Object[]{key, ipgpIpg});
            return findPnByKey(key).orElseThrow(() -> new DaoException("ipgPn исчез после INSERT: " + key));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            if (isUniqueViolation(exception)) {
                throw new IllegalStateException(
                        "Нарушение unique (ipg,cstAgPn,sh): уже есть пункт для этой стройки и схемы",
                        exception);
            }
            throw new DaoException("Не удалось создать ipgPn", exception);
        }
    }

    @Override
    public List<Integer> bulkCreatePnsWithSt(int ipgKey, List<IpgPnBulkDraft> drafts) {
        Objects.requireNonNull(drafts, "drafts");
        if (drafts.isEmpty()) {
            return List.of();
        }
        String insertPn = "INSERT INTO " + q("ipgPn")
                + " (ipgpIpg, ipgpNum, ipgpCstAgPn, ipgpSmTtl, ipgpSmWrk, ipgpSmEqu, ipgpSmOth, "
                + "  ipgpSmAgFee, ipgpCostAdjust, ipgpSmReserv, ipgpTskCms, ipgpSh) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        String insertSt = "INSERT INTO " + q("ipgStPn") + " (ipgspSt, ipgspPn) VALUES (?, ?)";
        String checkUnique = "SELECT ipgpKey FROM " + q("ipgPn")
                + " WHERE ipgpIpg=? AND ipgpCstAgPn=? AND ipgpSh=?";
        List<Integer> created = new ArrayList<>(drafts.size());
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                for (IpgPnBulkDraft draft : drafts) {
                    try (PreparedStatement check = connection.prepareStatement(checkUnique)) {
                        check.setInt(1, ipgKey);
                        check.setInt(2, draft.cstAgPnKey());
                        check.setInt(3, draft.ipgpSh());
                        try (ResultSet rs = check.executeQuery()) {
                            if (rs.next()) {
                                throw new IllegalStateException(
                                        "Дубликат unique (ipg,cstAgPn,sh): уже ipgpKey="
                                                + rs.getInt(1)
                                                + " (stagingRow=" + draft.stagingRowId() + ")");
                            }
                        }
                    }
                    ensureStIpgExists(connection, draft.stiKey());
                    int pnKey;
                    try (PreparedStatement statement = connection.prepareStatement(
                            insertPn, Statement.RETURN_GENERATED_KEYS)) {
                        bindPnParams(
                                statement,
                                ipgKey,
                                draft.ipgpNum(),
                                draft.cstAgPnKey(),
                                draft.ipgpSmTtl(),
                                draft.ipgpSmWrk(),
                                draft.ipgpSmEqu(),
                                draft.ipgpSmOth(),
                                null,
                                null,
                                null,
                                draft.ipgpTskCms(),
                                draft.ipgpSh());
                        statement.executeUpdate();
                        pnKey = readGeneratedKey(statement, "ipgpKey");
                    }
                    try (PreparedStatement statement = connection.prepareStatement(insertSt)) {
                        statement.setInt(1, draft.stiKey());
                        statement.setInt(2, pnKey);
                        statement.executeUpdate();
                    }
                    seedIpgPnLim(connection, pnKey,
                            draft.ipgpSmTtl(), draft.ipgpSmWrk(), draft.ipgpSmEqu(), draft.ipgpSmOth());
                    created.add(pnKey);
                }
                connection.commit();
                log.log(Level.INFO, "bulkCreatePnsWithSt ipg={0} created={1}",
                        new Object[]{ipgKey, created.size()});
                return List.copyOf(created);
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof IllegalStateException illegalStateException) {
                    throw illegalStateException;
                }
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                if (exception instanceof SQLException sqlException && isUniqueViolation(sqlException)) {
                    throw new IllegalStateException(
                            "Нарушение unique (ipg,cstAgPn,sh) при bulk apply",
                            sqlException);
                }
                throw new DaoException("Не удалось выполнить bulk apply ipgPn+ipgStPn для ipg=" + ipgKey,
                        exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось выполнить bulk apply ipgPn+ipgStPn для ipg=" + ipgKey,
                    exception);
        }
    }

    @Override
    public int createPnWithSt(int ipgKey, IpgPnBulkDraft draft) {
        Objects.requireNonNull(draft, "draft");
        List<Integer> keys = bulkCreatePnsWithSt(ipgKey, List.of(draft));
        if (keys.isEmpty()) {
            throw new DaoException("createPnWithSt: пустой результат для stagingRow=" + draft.stagingRowId());
        }
        return keys.get(0);
    }

    @Override
    public IpgPn updatePn(
            int ipgpKey,
            Integer ipgpNum,
            int ipgpCstAgPn,
            int ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms) {
        IpgPn existing = findPnByKey(ipgpKey)
                .orElseThrow(() -> new DaoException("ipgPn не найден: " + ipgpKey));
        ensureUniquePn(existing.ipgpIpg(), ipgpCstAgPn, ipgpSh, ipgpKey);
        String sql = "UPDATE " + q("ipgPn")
                + " SET ipgpNum=?, ipgpCstAgPn=?, ipgpSmTtl=?, ipgpSmWrk=?, ipgpSmEqu=?, ipgpSmOth=?, "
                + "ipgpSmAgFee=?, ipgpCostAdjust=?, ipgpSmReserv=?, ipgpTskCms=?, ipgpSh=? "
                + "WHERE ipgpKey=?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int idx = 1;
            if (ipgpNum == null) {
                statement.setNull(idx++, Types.INTEGER);
            } else {
                statement.setInt(idx++, ipgpNum);
            }
            statement.setInt(idx++, ipgpCstAgPn);
            setDecimal(statement, idx++, ipgpSmTtl);
            setDecimal(statement, idx++, ipgpSmWrk);
            setDecimal(statement, idx++, ipgpSmEqu);
            setDecimal(statement, idx++, ipgpSmOth);
            setDecimal(statement, idx++, ipgpSmAgFee);
            setDecimal(statement, idx++, ipgpCostAdjust);
            setDecimal(statement, idx++, ipgpSmReserv);
            if (ipgpTskCms == null) {
                statement.setNull(idx++, Types.NVARCHAR);
            } else {
                statement.setNString(idx++, ipgpTskCms);
            }
            statement.setInt(idx++, ipgpSh);
            statement.setInt(idx, ipgpKey);
            if (statement.executeUpdate() == 0) {
                throw new DaoException("ipgPn не найден: " + ipgpKey);
            }
            replaceIpgPnLim(connection, ipgpKey, ipgpSmTtl, ipgpSmWrk, ipgpSmEqu, ipgpSmOth);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            if (isUniqueViolation(exception)) {
                throw new IllegalStateException(
                        "Нарушение unique (ipg,cstAgPn,sh): уже есть пункт для этой стройки и схемы",
                        exception);
            }
            throw new DaoException("Не удалось обновить ipgPn=" + ipgpKey, exception);
        }
        return findPnByKey(ipgpKey).orElseThrow(() -> new DaoException("ipgPn исчез после UPDATE: " + ipgpKey));
    }

    @Override
    public void deletePn(int ipgpKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                if (hasChild(connection, "ipgUtPlP", "iuplpIpgPn", ipgpKey)) {
                    throw new IllegalStateException(
                            "У пункта есть планы UtPl (ipgUtPlP) — удаление запрещено: " + ipgpKey);
                }
                if (hasChild(connection, "ipgPnLim", "ipgplPn", ipgpKey)) {
                    throw new IllegalStateException(
                            "У пункта есть лимиты (ipgPnLim) — удаление запрещено: " + ipgpKey);
                }
                try (PreparedStatement deleteSt = connection.prepareStatement(
                        "DELETE FROM " + q("ipgStPn") + " WHERE ipgspPn = ?")) {
                    deleteSt.setInt(1, ipgpKey);
                    deleteSt.executeUpdate();
                }
                try (PreparedStatement deletePn = connection.prepareStatement(
                        "DELETE FROM " + q("ipgPn") + " WHERE ipgpKey = ?")) {
                    deletePn.setInt(1, ipgpKey);
                    if (deletePn.executeUpdate() == 0) {
                        throw new DaoException("ipgPn не найден: " + ipgpKey);
                    }
                }
                connection.commit();
                log.log(Level.INFO, "Deleted ipgPn {0}", ipgpKey);
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось удалить ipgPn=" + ipgpKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить ipgPn=" + ipgpKey, exception);
        }
    }

    @Override
    public List<IpgStPn> findStPnByPn(int ipgpKey) {
        String sql = ""
                + "SELECT sp.ipgspKey, sp.ipgspPn, sp.ipgspSt, nm.stinNm "
                + "FROM " + q("ipgStPn") + " sp "
                + "LEFT JOIN " + q("stIpgNm") + " nm ON nm.stinKey = ("
                + "  SELECT MIN(n2.stinKey) FROM " + q("stIpgNm") + " n2 WHERE n2.stinIpg = sp.ipgspSt) "
                + "WHERE sp.ipgspPn = ? ORDER BY sp.ipgspKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgpKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgStPn> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(new IpgStPn(
                            resultSet.getInt("ipgspKey"),
                            resultSet.getInt("ipgspPn"),
                            resultSet.getInt("ipgspSt"),
                            resultSet.getNString("stinNm")
                    ));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать ipgStPn для pn=" + ipgpKey, exception);
        }
    }

    @Override
    public IpgStPn addStPn(int ipgpKey, int stiKey) {
        ensurePnExists(ipgpKey);
        ensureStIpgExists(stiKey);
        if (findStPnByPn(ipgpKey).stream().anyMatch(row -> row.ipgspSt() == stiKey)) {
            throw new IllegalStateException("Привязка уже есть: pn=" + ipgpKey + " st=" + stiKey);
        }
        String sql = "INSERT INTO " + q("ipgStPn") + " (ipgspSt, ipgspPn) VALUES (?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, stiKey);
            statement.setInt(2, ipgpKey);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "ipgspKey");
            return findStPnByPn(ipgpKey).stream()
                    .filter(row -> row.ipgspKey() == key)
                    .findFirst()
                    .orElse(new IpgStPn(key, ipgpKey, stiKey, null));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать ipgStPn", exception);
        }
    }

    @Override
    public void removeStPn(int ipgspKey) {
        String sql = "DELETE FROM " + q("ipgStPn") + " WHERE ipgspKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgspKey);
            if (statement.executeUpdate() == 0) {
                throw new DaoException("ipgStPn не найден: " + ipgspKey);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить ipgStPn=" + ipgspKey, exception);
        }
    }

    @Override
    public List<IpgStPn> setStPn(int ipgpKey, List<Integer> stiKeys) {
        Objects.requireNonNull(stiKeys, "stiKeys");
        ensurePnExists(ipgpKey);
        LinkedHashSet<Integer> unique = new LinkedHashSet<>(stiKeys);
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                try (PreparedStatement delete = connection.prepareStatement(
                        "DELETE FROM " + q("ipgStPn") + " WHERE ipgspPn = ?")) {
                    delete.setInt(1, ipgpKey);
                    delete.executeUpdate();
                }
                String insert = "INSERT INTO " + q("ipgStPn") + " (ipgspSt, ipgspPn) VALUES (?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insert)) {
                    for (Integer stiKey : unique) {
                        ensureStIpgExists(connection, stiKey);
                        statement.setInt(1, stiKey);
                        statement.setInt(2, ipgpKey);
                        statement.addBatch();
                    }
                    if (!unique.isEmpty()) {
                        statement.executeBatch();
                    }
                }
                connection.commit();
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось заменить ipgStPn для pn=" + ipgpKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось заменить ipgStPn для pn=" + ipgpKey, exception);
        }
        return findStPnByPn(ipgpKey);
    }

    @Override
    public List<IpgSh> findAllSh() {
        String sql = "SELECT ipgsKey, ipgsNm FROM " + q("ipgSh") + " ORDER BY ipgsKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<IpgSh> rows = new ArrayList<>();
            while (resultSet.next()) {
                rows.add(new IpgSh(resultSet.getInt("ipgsKey"), resultSet.getNString("ipgsNm")));
            }
            return List.copyOf(rows);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать ipgSh", exception);
        }
    }

    private void bindPnParams(
            PreparedStatement statement,
            int ipgpIpg,
            Integer ipgpNum,
            int ipgpCstAgPn,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms,
            int ipgpSh) throws SQLException {
        statement.setInt(1, ipgpIpg);
        if (ipgpNum == null) {
            statement.setNull(2, Types.INTEGER);
        } else {
            statement.setInt(2, ipgpNum);
        }
        statement.setInt(3, ipgpCstAgPn);
        setDecimal(statement, 4, ipgpSmTtl);
        setDecimal(statement, 5, ipgpSmWrk);
        setDecimal(statement, 6, ipgpSmEqu);
        setDecimal(statement, 7, ipgpSmOth);
        setDecimal(statement, 8, ipgpSmAgFee);
        setDecimal(statement, 9, ipgpCostAdjust);
        setDecimal(statement, 10, ipgpSmReserv);
        if (ipgpTskCms == null) {
            statement.setNull(11, Types.NVARCHAR);
        } else {
            statement.setNString(11, ipgpTskCms);
        }
        statement.setInt(12, ipgpSh);
    }

    private void ensureUniquePn(int ipgKey, int cstAgPn, int sh, Integer excludePnKey) {
        String sql = "SELECT ipgpKey FROM " + q("ipgPn")
                + " WHERE ipgpIpg=? AND ipgpCstAgPn=? AND ipgpSh=?"
                + (excludePnKey != null ? " AND ipgpKey<>?" : "");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            statement.setInt(2, cstAgPn);
            statement.setInt(3, sh);
            if (excludePnKey != null) {
                statement.setInt(4, excludePnKey);
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    throw new IllegalStateException(
                            "Дубликат unique (ipg,cstAgPn,sh): уже ipgpKey=" + resultSet.getInt(1));
                }
            }
        } catch (IllegalStateException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось проверить unique ipgPn", exception);
        }
    }

    private void ensurePnExists(int ipgpKey) {
        findPnByKey(ipgpKey).orElseThrow(() -> new DaoException("ipgPn не найден: " + ipgpKey));
    }

    private void ensureStIpgExists(int stiKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            ensureStIpgExists(connection, stiKey);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось проверить stIpg=" + stiKey, exception);
        }
    }

    private void ensureStIpgExists(Connection connection, int stiKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("stIpg") + " WHERE stiKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new DaoException("Узел stIpg не найден: " + stiKey);
                }
            }
        }
    }

    private boolean hasChild(Connection connection, String table, String column, int pnKey)
            throws SQLException {
        String sql = "SELECT 1 FROM " + q(table) + " WHERE " + column + " = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, pnKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private IpgFull mapIpg(ResultSet resultSet) throws SQLException {
        Date end = resultSet.getDate("ipgEnd");
        Integer repl = resultSet.getObject("ipgRepl") == null ? null : resultSet.getInt("ipgRepl");
        Integer yyYear = resultSet.getObject("ipgYyYear") == null ? null : resultSet.getInt("ipgYyYear");
        Integer year = resultSet.getObject("yearNum") == null ? null : resultSet.getInt("yearNum");
        return new IpgFull(
                resultSet.getInt("ipgKey"),
                resultSet.getInt("ipgOg"),
                resultSet.getNString("ogNm"),
                resultSet.getNString("ipgNm"),
                resultSet.getInt("ipgYy"),
                year,
                resultSet.getShort("ipgNum"),
                resultSet.getDate("ipgStr").toLocalDate(),
                end == null ? null : end.toLocalDate(),
                repl,
                resultSet.getInt("ipgStRlSh"),
                resultSet.getNString("stnName"),
                yyYear
        );
    }

    private IpgPn mapPn(ResultSet resultSet) throws SQLException {
        return new IpgPn(
                resultSet.getInt("ipgpKey"),
                resultSet.getInt("ipgpIpg"),
                resultSet.getObject("ipgpNum") == null ? null : resultSet.getInt("ipgpNum"),
                resultSet.getInt("ipgpCstAgPn"),
                resultSet.getNString("cstapIpgPnN"),
                resultSet.getNString("cstapCstName"),
                resultSet.getNString("cstapOgName"),
                resultSet.getBigDecimal("ipgpSmTtl"),
                resultSet.getBigDecimal("ipgpSmWrk"),
                resultSet.getBigDecimal("ipgpSmEqu"),
                resultSet.getBigDecimal("ipgpSmOth"),
                resultSet.getBigDecimal("ipgpSmAgFee"),
                resultSet.getBigDecimal("ipgpCostAdjust"),
                resultSet.getBigDecimal("ipgpSmReserv"),
                resultSet.getNString("ipgpTskCms"),
                resultSet.getInt("ipgpSh"),
                resultSet.getNString("ipgsNm")
        );
    }

    private static void setDecimal(PreparedStatement statement, int index, BigDecimal value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DECIMAL);
        } else {
            statement.setBigDecimal(index, value);
        }
    }

    /**
     * Seed {@code ipgPnLim} ← Sm* (212/195/172/187), только ненулевые (ADR 012 / O1 хвост).
     */
    private void seedIpgPnLim(
            Connection connection,
            int ipgpKey,
            BigDecimal ttl,
            BigDecimal wrk,
            BigDecimal equ,
            BigDecimal oth) throws SQLException {
        insertLimIfNonZero(connection, ipgpKey, 212, ttl);
        insertLimIfNonZero(connection, ipgpKey, 195, wrk);
        insertLimIfNonZero(connection, ipgpKey, 172, equ);
        insertLimIfNonZero(connection, ipgpKey, 187, oth);
    }

    private void replaceIpgPnLim(
            Connection connection,
            int ipgpKey,
            BigDecimal ttl,
            BigDecimal wrk,
            BigDecimal equ,
            BigDecimal oth) throws SQLException {
        try (PreparedStatement del = connection.prepareStatement(
                "DELETE FROM " + q("ipgPnLim") + " WHERE ipgplPn=? AND ipgplStCost IN (212,195,172,187)")) {
            del.setInt(1, ipgpKey);
            del.executeUpdate();
        }
        seedIpgPnLim(connection, ipgpKey, ttl, wrk, equ, oth);
    }

    private void insertLimIfNonZero(Connection connection, int ipgpKey, int stCost, BigDecimal lim)
            throws SQLException {
        if (lim == null || lim.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }
        String sql = "INSERT INTO " + q("ipgPnLim") + " (ipgplPn, ipgplStCost, ipgplLim) VALUES (?, ?, ?)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgpKey);
            statement.setInt(2, stCost);
            statement.setBigDecimal(3, lim);
            statement.executeUpdate();
        }
    }

    private static boolean isUniqueViolation(SQLException exception) {
        String state = exception.getSQLState();
        return "23000".equals(state) || exception.getErrorCode() == 2627 || exception.getErrorCode() == 2601;
    }

    private int readGeneratedKey(PreparedStatement statement, String label) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (!keys.next()) {
                throw new DaoException("Не получен IDENTITY для " + label);
            }
            return keys.getInt(1);
        }
    }
}
