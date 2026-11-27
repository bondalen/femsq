package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.StCostNm;
import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link StIpgStructureDao} для Structure CRUD (C2 §2.4.1 / O2 §4.0.1).
 */
public class JdbcStIpgStructureDao implements StIpgStructureDao {

    private static final Logger log = Logger.getLogger(JdbcStIpgStructureDao.class.getName());
    private static final int ST_TYPE_IPG = 1;
    private static final int ST_TYPE_COST = 2;

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcStIpgStructureDao(
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

    @Override
    public List<StNetworkFull> findNetworksByType(int stnType) {
        String sql = "SELECT stnKey, stnType, stnName, stnRoot FROM " + q("stNet")
                + " WHERE stnType = ? ORDER BY stnName";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stnType);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<StNetworkFull> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(mapNetwork(resultSet));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить список схем stNet", exception);
        }
    }

    @Override
    public Optional<StNetworkFull> findNetworkByKey(int stnKey) {
        String sql = "SELECT stnKey, stnType, stnName, stnRoot FROM " + q("stNet") + " WHERE stnKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stnKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapNetwork(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать stNet=" + stnKey, exception);
        }
    }

    @Override
    public List<StIpgTreeNode> findTree(int stNetKey, int rootKey) {
        String sql = ""
                + "SELECT f.strChild, f.strParent, f.stpnNum, f.pnLevel, f.stNum, f.Nm, "
                + "  r.strKey AS stRelKey, p.stnpKey AS stNetPnKey "
                + "FROM " + q("fnSt") + "(?, ?) f "
                + "LEFT JOIN " + q("stRel") + " r "
                + "  ON r.strChild = f.strChild AND (r.strParent = f.strParent "
                + "      OR (r.strParent IS NULL AND f.strParent IS NULL)) "
                + "LEFT JOIN " + q("stNetPn") + " p "
                + "  ON p.stnpStRel = r.strKey AND p.stpnStNet = ? "
                + "ORDER BY f.stNum";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stNetKey);
            statement.setInt(2, rootKey);
            statement.setInt(3, stNetKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<StIpgTreeNode> rows = new ArrayList<>();
                while (resultSet.next()) {
                    Integer parent = resultSet.getObject("strParent") == null
                            ? null
                            : resultSet.getInt("strParent");
                    Integer relKey = resultSet.getObject("stRelKey") == null
                            ? null
                            : resultSet.getInt("stRelKey");
                    Integer pnKey = resultSet.getObject("stNetPnKey") == null
                            ? null
                            : resultSet.getInt("stNetPnKey");
                    rows.add(new StIpgTreeNode(
                            resultSet.getInt("strChild"),
                            parent,
                            resultSet.getObject("stpnNum") == null ? null : resultSet.getInt("stpnNum"),
                            resultSet.getInt("pnLevel"),
                            resultSet.getString("stNum"),
                            resultSet.getNString("Nm"),
                            relKey,
                            pnKey
                    ));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException(
                    "Не удалось построить дерево fnSt(" + stNetKey + "," + rootKey + ")", exception);
        }
    }

    @Override
    public StNetworkFull createNetwork(int stnType, String name, int rootKey) {
        Objects.requireNonNull(name, "name");
        String sql = "INSERT INTO " + q("stNet") + " (stnType, stnName, stnRoot) VALUES (?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, stnType);
            statement.setNString(2, name.trim());
            statement.setInt(3, rootKey);
            statement.executeUpdate();
            int key = readGeneratedKey(statement, "stnKey");
            return new StNetworkFull(key, stnType, name.trim(), rootKey);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать stNet", exception);
        }
    }

    @Override
    public StNetworkFull updateNetworkName(int stnKey, String name) {
        Objects.requireNonNull(name, "name");
        String sql = "UPDATE " + q("stNet") + " SET stnName = ? WHERE stnKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, name.trim());
            statement.setInt(2, stnKey);
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("stNet не найден: " + stnKey);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось переименовать stNet=" + stnKey, exception);
        }
        return findNetworkByKey(stnKey)
                .orElseThrow(() -> new DaoException("stNet исчез после UPDATE: " + stnKey));
    }

    @Override
    public StNetworkFull cloneNetwork(int sourceKey, String newName) {
        Objects.requireNonNull(newName, "newName");
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                StNetworkFull source = findNetworkOn(connection, sourceKey)
                        .orElseThrow(() -> new DaoException("Источник stNet не найден: " + sourceKey));
                int newKey;
                String insertNet = "INSERT INTO " + q("stNet") + " (stnType, stnName, stnRoot) VALUES (?, ?, ?)";
                try (PreparedStatement statement =
                             connection.prepareStatement(insertNet, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, source.stnType());
                    statement.setNString(2, newName.trim());
                    statement.setInt(3, source.stnRoot());
                    statement.executeUpdate();
                    newKey = readGeneratedKey(statement, "stnKey");
                }
                String copyPn = ""
                        + "INSERT INTO " + q("stNetPn") + " (stnpStRel, stpnStNet, stpnNum) "
                        + "SELECT stnpStRel, ?, stpnNum FROM " + q("stNetPn") + " WHERE stpnStNet = ?";
                try (PreparedStatement statement = connection.prepareStatement(copyPn)) {
                    statement.setInt(1, newKey);
                    statement.setInt(2, sourceKey);
                    statement.executeUpdate();
                }
                connection.commit();
                return new StNetworkFull(newKey, source.stnType(), newName.trim(), source.stnRoot());
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof DaoException daoException) {
                    throw daoException;
                }
                throw new DaoException("Не удалось клонировать stNet=" + sourceKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось клонировать stNet=" + sourceKey, exception);
        }
    }

    @Override
    public int createChildNode(int stNetKey, int parentKey, String name, Integer stpnNum) {
        Objects.requireNonNull(name, "name");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Имя узла пустое");
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                StNetworkFull network = findNetworkOn(connection, stNetKey)
                        .orElseThrow(() -> new DaoException("stNet не найден: " + stNetKey));
                int stnType = network.stnType();
                if (stnType != ST_TYPE_IPG && stnType != ST_TYPE_COST) {
                    throw new IllegalArgumentException(
                            "Создание узла только для stnType=1|2, получено: " + stnType);
                }
                ensureNodeOfType(connection, parentKey, stnType);
                Timestamp now = Timestamp.from(Instant.now());
                String token = "femsq-create-" + java.util.UUID.randomUUID();
                int stKey;
                if (stnType == ST_TYPE_IPG) {
                    // ags.stIpg_insert (INSTEAD OF): сам создаёт ags.st + строку stIpg.
                    String insertIpg = "INSERT INTO " + q("stIpg") + " (stiLim, stiNote) VALUES (NULL, ?)";
                    try (PreparedStatement statement = connection.prepareStatement(insertIpg)) {
                        statement.setNString(1, token);
                        statement.executeUpdate();
                    }
                    String selectKey = "SELECT stiKey FROM " + q("stIpg") + " WHERE stiNote = ?";
                    try (PreparedStatement statement = connection.prepareStatement(selectKey)) {
                        statement.setNString(1, token);
                        try (ResultSet resultSet = statement.executeQuery()) {
                            if (!resultSet.next()) {
                                throw new DaoException("Триггер stIpg_insert не вернул stiKey для токена");
                            }
                            stKey = resultSet.getInt(1);
                        }
                    }
                    String clearNote = "UPDATE " + q("stIpg") + " SET stiNote = NULL WHERE stiKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(clearNote)) {
                        statement.setInt(1, stKey);
                        statement.executeUpdate();
                    }
                    String insertNm = "INSERT INTO " + q("stIpgNm")
                            + " (stinIpg, stinNm, stinNote, stinTimeOfEntry) VALUES (?, ?, NULL, ?)";
                    try (PreparedStatement statement = connection.prepareStatement(insertNm)) {
                        statement.setInt(1, stKey);
                        statement.setNString(2, name.trim());
                        statement.setTimestamp(3, now);
                        statement.executeUpdate();
                    }
                } else {
                    // ags.stCost_insert (INSTEAD OF): сам создаёт ags.st(stType=2) + stCost.
                    String insertCost = "INSERT INTO " + q("stCost") + " (stcNote) VALUES (?)";
                    try (PreparedStatement statement = connection.prepareStatement(insertCost)) {
                        statement.setNString(1, token);
                        statement.executeUpdate();
                    }
                    String selectKey = "SELECT stcKey FROM " + q("stCost") + " WHERE stcNote = ?";
                    try (PreparedStatement statement = connection.prepareStatement(selectKey)) {
                        statement.setNString(1, token);
                        try (ResultSet resultSet = statement.executeQuery()) {
                            if (!resultSet.next()) {
                                throw new DaoException("Триггер stCost_insert не вернул stcKey для токена");
                            }
                            stKey = resultSet.getInt(1);
                        }
                    }
                    String clearNote = "UPDATE " + q("stCost") + " SET stcNote = NULL WHERE stcKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(clearNote)) {
                        statement.setInt(1, stKey);
                        statement.executeUpdate();
                    }
                    String insertNm = "INSERT INTO " + q("stCostNm")
                            + " (stcnCost, stcnNm, stcnNote, stcnTimeOfEntry) VALUES (?, ?, NULL, ?)";
                    try (PreparedStatement statement = connection.prepareStatement(insertNm)) {
                        statement.setInt(1, stKey);
                        statement.setNString(2, name.trim());
                        statement.setTimestamp(3, now);
                        statement.executeUpdate();
                    }
                }
                int relKey = findOrCreateRel(connection, parentKey, stKey);
                int num = stpnNum != null ? stpnNum : nextSiblingNum(connection, stNetKey, parentKey);
                String insertPn = "INSERT INTO " + q("stNetPn")
                        + " (stnpStRel, stpnStNet, stpnNum) VALUES (?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insertPn)) {
                    statement.setInt(1, relKey);
                    statement.setInt(2, stNetKey);
                    statement.setInt(3, num);
                    statement.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "Created stType={0} node {1} under {2} in net {3}",
                        new Object[]{stnType, stKey, parentKey, stNetKey});
                return stKey;
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось создать узел структуры", exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать узел структуры", exception);
        }
    }

    @Override
    public void renameNode(int stiKey, String name) {
        Objects.requireNonNull(name, "name");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Имя узла пустое");
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int stType = readStType(connection, stiKey);
                Timestamp now = Timestamp.from(Instant.now());
                if (stType == ST_TYPE_COST) {
                    String update = "UPDATE " + q("stCostNm")
                            + " SET stcnNm = ? WHERE stcnKey = ("
                            + "SELECT MIN(stcnKey) FROM " + q("stCostNm") + " WHERE stcnCost = ?)";
                    try (PreparedStatement statement = connection.prepareStatement(update)) {
                        statement.setNString(1, name.trim());
                        statement.setInt(2, stiKey);
                        int updated = statement.executeUpdate();
                        if (updated == 0) {
                            String insert = "INSERT INTO " + q("stCostNm")
                                    + " (stcnCost, stcnNm, stcnNote, stcnTimeOfEntry) VALUES (?, ?, NULL, ?)";
                            try (PreparedStatement insertStatement = connection.prepareStatement(insert)) {
                                insertStatement.setInt(1, stiKey);
                                insertStatement.setNString(2, name.trim());
                                insertStatement.setTimestamp(3, now);
                                insertStatement.executeUpdate();
                            }
                        }
                    }
                } else if (stType == ST_TYPE_IPG) {
                    String update = "UPDATE " + q("stIpgNm")
                            + " SET stinNm = ? WHERE stinKey = ("
                            + "SELECT MIN(stinKey) FROM " + q("stIpgNm") + " WHERE stinIpg = ?)";
                    try (PreparedStatement statement = connection.prepareStatement(update)) {
                        statement.setNString(1, name.trim());
                        statement.setInt(2, stiKey);
                        int updated = statement.executeUpdate();
                        if (updated == 0) {
                            String insert = "INSERT INTO " + q("stIpgNm")
                                    + " (stinIpg, stinNm, stinNote, stinTimeOfEntry) VALUES (?, ?, NULL, ?)";
                            try (PreparedStatement insertStatement = connection.prepareStatement(insert)) {
                                insertStatement.setInt(1, stiKey);
                                insertStatement.setNString(2, name.trim());
                                insertStatement.setTimestamp(3, now);
                                insertStatement.executeUpdate();
                            }
                        }
                    }
                } else {
                    throw new IllegalArgumentException(
                            "Переименование только для stType=1|2, получено: " + stType);
                }
                connection.commit();
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось переименовать узел " + stiKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось переименовать узел " + stiKey, exception);
        }
    }

    @Override
    public List<StIpgNm> findNodeNames(int stiKey) {
        String sql = "SELECT stinKey, stinIpg, stinNm FROM " + q("stIpgNm")
                + " WHERE stinIpg = ? ORDER BY stinKey";
        List<StIpgNm> rows = new ArrayList<>();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(new StIpgNm(
                            resultSet.getInt("stinKey"),
                            resultSet.getInt("stinIpg"),
                            resultSet.getNString("stinNm")
                    ));
                }
            }
            return rows;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать имена узла " + stiKey, exception);
        }
    }

    @Override
    public List<StCostNm> findCostNodeNames(int stcKey) {
        String sql = "SELECT stcnKey, stcnCost, stcnNm FROM " + q("stCostNm")
                + " WHERE stcnCost = ? ORDER BY stcnKey";
        List<StCostNm> rows = new ArrayList<>();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stcKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(new StCostNm(
                            resultSet.getInt("stcnKey"),
                            resultSet.getInt("stcnCost"),
                            resultSet.getNString("stcnNm")
                    ));
                }
            }
            return rows;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать имена узла затрат " + stcKey, exception);
        }
    }

    @Override
    public int addNodeName(int stiKey, String name) {
        Objects.requireNonNull(name, "name");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Имя узла пустое");
        }
        String trimmed = name.trim();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ensureNodeOfType(connection, stiKey, ST_TYPE_IPG);
                String dup = "SELECT 1 FROM " + q("stIpgNm") + " WHERE stinIpg = ? AND stinNm = ?";
                try (PreparedStatement statement = connection.prepareStatement(dup)) {
                    statement.setInt(1, stiKey);
                    statement.setNString(2, trimmed);
                    try (ResultSet resultSet = statement.executeQuery()) {
                        if (resultSet.next()) {
                            throw new IllegalArgumentException(
                                    "Имя уже есть у узла " + stiKey + ": " + trimmed);
                        }
                    }
                }
                int stinKey;
                String insert = "INSERT INTO " + q("stIpgNm")
                        + " (stinIpg, stinNm, stinNote, stinTimeOfEntry) VALUES (?, ?, NULL, ?)";
                try (PreparedStatement statement =
                             connection.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, stiKey);
                    statement.setNString(2, trimmed);
                    statement.setTimestamp(3, Timestamp.from(Instant.now()));
                    statement.executeUpdate();
                    stinKey = readGeneratedKey(statement, "stinKey");
                }
                connection.commit();
                log.log(Level.INFO, "Added stIpgNm {0} for sti={1}", new Object[]{stinKey, stiKey});
                return stinKey;
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось добавить имя узла " + stiKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось добавить имя узла " + stiKey, exception);
        }
    }

    @Override
    public int addCostNodeName(int stcKey, String name) {
        Objects.requireNonNull(name, "name");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Имя узла пустое");
        }
        String trimmed = name.trim();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ensureNodeOfType(connection, stcKey, ST_TYPE_COST);
                String dup = "SELECT 1 FROM " + q("stCostNm") + " WHERE stcnCost = ? AND stcnNm = ?";
                try (PreparedStatement statement = connection.prepareStatement(dup)) {
                    statement.setInt(1, stcKey);
                    statement.setNString(2, trimmed);
                    try (ResultSet resultSet = statement.executeQuery()) {
                        if (resultSet.next()) {
                            throw new IllegalArgumentException(
                                    "Имя уже есть у узла затрат " + stcKey + ": " + trimmed);
                        }
                    }
                }
                int stcnKey;
                String insert = "INSERT INTO " + q("stCostNm")
                        + " (stcnCost, stcnNm, stcnNote, stcnTimeOfEntry) VALUES (?, ?, NULL, ?)";
                try (PreparedStatement statement =
                             connection.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, stcKey);
                    statement.setNString(2, trimmed);
                    statement.setTimestamp(3, Timestamp.from(Instant.now()));
                    statement.executeUpdate();
                    stcnKey = readGeneratedKey(statement, "stcnKey");
                }
                connection.commit();
                log.log(Level.INFO, "Added stCostNm {0} for stc={1}", new Object[]{stcnKey, stcKey});
                return stcnKey;
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось добавить имя узла затрат " + stcKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось добавить имя узла затрат " + stcKey, exception);
        }
    }

    @Override
    public void attachEdgeToNetwork(int stNetKey, int parentKey, int childKey, Integer stpnNum) {
        if (parentKey == childKey) {
            throw new IllegalArgumentException("parent и child совпадают");
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                StNetworkFull network = findNetworkOn(connection, stNetKey)
                        .orElseThrow(() -> new DaoException("stNet не найден: " + stNetKey));
                int stnType = network.stnType();
                if (stnType != ST_TYPE_IPG && stnType != ST_TYPE_COST) {
                    throw new IllegalArgumentException(
                            "attach только для stnType=1|2, получено: " + stnType);
                }
                ensureNodeOfType(connection, parentKey, stnType);
                ensureNodeOfType(connection, childKey, stnType);
                int relKey = findOrCreateRel(connection, parentKey, childKey);
                if (relInNetwork(connection, stNetKey, relKey)) {
                    throw new IllegalStateException(
                            "Ребро уже в схеме " + stNetKey + ": " + parentKey + "→" + childKey);
                }
                int num = stpnNum != null ? stpnNum : nextSiblingNum(connection, stNetKey, parentKey);
                String insertPn = "INSERT INTO " + q("stNetPn")
                        + " (stnpStRel, stpnStNet, stpnNum) VALUES (?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insertPn)) {
                    statement.setInt(1, relKey);
                    statement.setInt(2, stNetKey);
                    statement.setInt(3, num);
                    statement.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "Attached edge {0}→{1} to net {2}",
                        new Object[]{parentKey, childKey, stNetKey});
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось привязать ребро к схеме", exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось привязать ребро к схеме", exception);
        }
    }

    @Override
    public void moveEdgeInNetwork(
            int stNetKey, int childKey, int fromParentKey, int toParentKey, Integer stpnNum) {
        if (fromParentKey == toParentKey) {
            throw new IllegalArgumentException("fromParent и toParent совпадают");
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                StNetworkFull network = findNetworkOn(connection, stNetKey)
                        .orElseThrow(() -> new DaoException("stNet не найден: " + stNetKey));
                int stnType = network.stnType();
                if (stnType != ST_TYPE_IPG && stnType != ST_TYPE_COST) {
                    throw new IllegalArgumentException(
                            "move только для stnType=1|2, получено: " + stnType);
                }
                ensureNodeOfType(connection, childKey, stnType);
                ensureNodeOfType(connection, fromParentKey, stnType);
                ensureNodeOfType(connection, toParentKey, stnType);
                Integer fromRel = findRelKey(connection, fromParentKey, childKey);
                if (fromRel == null || !relInNetwork(connection, stNetKey, fromRel)) {
                    throw new DaoException(
                            "Исходное ребро не в схеме " + stNetKey + ": "
                                    + fromParentKey + "→" + childKey);
                }
                String deletePn = "DELETE FROM " + q("stNetPn")
                        + " WHERE stpnStNet = ? AND stnpStRel = ?";
                try (PreparedStatement statement = connection.prepareStatement(deletePn)) {
                    statement.setInt(1, stNetKey);
                    statement.setInt(2, fromRel);
                    statement.executeUpdate();
                }
                if (!relUsedInAnyNet(connection, fromRel)) {
                    String deleteRel = "DELETE FROM " + q("stRel") + " WHERE strKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteRel)) {
                        statement.setInt(1, fromRel);
                        statement.executeUpdate();
                    }
                }
                int toRel = findOrCreateRel(connection, toParentKey, childKey);
                if (relInNetwork(connection, stNetKey, toRel)) {
                    throw new IllegalStateException(
                            "Целевое ребро уже в схеме: " + toParentKey + "→" + childKey);
                }
                int num = stpnNum != null ? stpnNum : nextSiblingNum(connection, stNetKey, toParentKey);
                String insertPn = "INSERT INTO " + q("stNetPn")
                        + " (stnpStRel, stpnStNet, stpnNum) VALUES (?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(insertPn)) {
                    statement.setInt(1, toRel);
                    statement.setInt(2, stNetKey);
                    statement.setInt(3, num);
                    statement.executeUpdate();
                }
                connection.commit();
                log.log(Level.INFO, "Moved child {0} in net {1}: {2}→{3}",
                        new Object[]{childKey, stNetKey, fromParentKey, toParentKey});
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось перенести узел в схеме", exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось перенести узел в схеме", exception);
        }
    }

    @Override
    public void detachEdgeFromNetwork(int stNetKey, int parentKey, int childKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                Integer relKey = findRelKey(connection, parentKey, childKey);
                if (relKey == null) {
                    throw new DaoException("Ребро не найдено: " + parentKey + "→" + childKey);
                }
                String deletePn = "DELETE FROM " + q("stNetPn")
                        + " WHERE stpnStNet = ? AND stnpStRel = ?";
                try (PreparedStatement statement = connection.prepareStatement(deletePn)) {
                    statement.setInt(1, stNetKey);
                    statement.setInt(2, relKey);
                    int deleted = statement.executeUpdate();
                    if (deleted == 0) {
                        throw new DaoException("Ребро не входит в схему " + stNetKey);
                    }
                }
                if (!relUsedInAnyNet(connection, relKey)) {
                    String deleteRel = "DELETE FROM " + q("stRel") + " WHERE strKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteRel)) {
                        statement.setInt(1, relKey);
                        statement.executeUpdate();
                    }
                }
                connection.commit();
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось отсоединить ребро", exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось отсоединить ребро", exception);
        }
    }

    @Override
    public void deleteNode(int stNetKey, int stiKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int stType = readStType(connection, stiKey);
                if (stType == ST_TYPE_IPG) {
                    if (hasIpgStPn(connection, stiKey)) {
                        throw new IllegalStateException(
                                "Узел связан с пунктами ИП (ipgStPn) — удаление запрещено: " + stiKey);
                    }
                } else if (stType == ST_TYPE_COST) {
                    if (hasCostRefs(connection, stiKey)) {
                        throw new IllegalStateException(
                                "Узел затрат связан с lim/UtPl — удаление запрещено: " + stiKey);
                    }
                } else {
                    throw new IllegalArgumentException(
                            "Удаление только для stType=1|2, получено: " + stType);
                }
                if (usedInOtherNetworks(connection, stiKey, stNetKey)) {
                    throw new IllegalStateException(
                            "Узел входит в другие схемы — удаление запрещено: " + stiKey);
                }
                if (hasChildrenInNetwork(connection, stNetKey, stiKey)) {
                    throw new IllegalStateException(
                            "У узла есть потомки в схеме — сначала отсоедините детей: " + stiKey);
                }
                String deletePn = ""
                        + "DELETE p FROM " + q("stNetPn") + " p "
                        + "JOIN " + q("stRel") + " r ON r.strKey = p.stnpStRel "
                        + "WHERE p.stpnStNet = ? AND (r.strChild = ? OR r.strParent = ?)";
                try (PreparedStatement statement = connection.prepareStatement(deletePn)) {
                    statement.setInt(1, stNetKey);
                    statement.setInt(2, stiKey);
                    statement.setInt(3, stiKey);
                    statement.executeUpdate();
                }
                String deleteRel = ""
                        + "DELETE FROM " + q("stRel") + " "
                        + "WHERE (strChild = ? OR strParent = ?) "
                        + "AND strKey NOT IN (SELECT stnpStRel FROM " + q("stNetPn") + ")";
                try (PreparedStatement statement = connection.prepareStatement(deleteRel)) {
                    statement.setInt(1, stiKey);
                    statement.setInt(2, stiKey);
                    statement.executeUpdate();
                }
                if (stType == ST_TYPE_COST) {
                    String deleteNm = "DELETE FROM " + q("stCostNm") + " WHERE stcnCost = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteNm)) {
                        statement.setInt(1, stiKey);
                        statement.executeUpdate();
                    }
                    String deleteCost = "DELETE FROM " + q("stCost") + " WHERE stcKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteCost)) {
                        statement.setInt(1, stiKey);
                        statement.executeUpdate();
                    }
                } else {
                    String deleteNm = "DELETE FROM " + q("stIpgNm") + " WHERE stinIpg = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteNm)) {
                        statement.setInt(1, stiKey);
                        statement.executeUpdate();
                    }
                    String deleteIpg = "DELETE FROM " + q("stIpg") + " WHERE stiKey = ?";
                    try (PreparedStatement statement = connection.prepareStatement(deleteIpg)) {
                        statement.setInt(1, stiKey);
                        statement.executeUpdate();
                    }
                }
                String deleteSt = "DELETE FROM " + q("st") + " WHERE stKey = ?";
                try (PreparedStatement statement = connection.prepareStatement(deleteSt)) {
                    statement.setInt(1, stiKey);
                    statement.executeUpdate();
                }
                connection.commit();
            } catch (Exception exception) {
                connection.rollback();
                if (exception instanceof RuntimeException runtimeException) {
                    throw runtimeException;
                }
                throw new DaoException("Не удалось удалить узел " + stiKey, exception);
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить узел " + stiKey, exception);
        }
    }

    private StNetworkFull mapNetwork(ResultSet resultSet) throws SQLException {
        return new StNetworkFull(
                resultSet.getInt("stnKey"),
                resultSet.getInt("stnType"),
                resultSet.getNString("stnName"),
                resultSet.getInt("stnRoot")
        );
    }

    private Optional<StNetworkFull> findNetworkOn(Connection connection, int stnKey) throws SQLException {
        String sql = "SELECT stnKey, stnType, stnName, stnRoot FROM " + q("stNet") + " WHERE stnKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stnKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapNetwork(resultSet));
            }
        }
    }

    /**
     * Читает {@code st.stType}; бросает, если ключ отсутствует.
     */
    private int readStType(Connection connection, int stKey) throws SQLException {
        String sql = "SELECT stType FROM " + q("st") + " WHERE stKey = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new DaoException("Узел st не найден: " + stKey);
                }
                return resultSet.getInt(1);
            }
        }
    }

    /**
     * Проверяет существование узла с ожидаемым {@code stType} (1=ИПГ, 2=затраты).
     */
    private void ensureNodeOfType(Connection connection, int stKey, int expectedType) throws SQLException {
        int actual = readStType(connection, stKey);
        if (actual != expectedType) {
            throw new DaoException(
                    "Узел " + stKey + " имеет stType=" + actual + ", ожидался " + expectedType);
        }
    }

    /**
     * Запрет удаления узла затрат при ссылках из lim / UtPl.
     */
    private boolean hasCostRefs(Connection connection, int stcKey) throws SQLException {
        String sql = ""
                + "SELECT 1 WHERE EXISTS ("
                + "  SELECT 1 FROM " + q("ipgPnLim") + " WHERE ipgplStCost = ?"
                + ") OR EXISTS ("
                + "  SELECT 1 FROM " + q("ipgUtPlPnLmMn") + " WHERE iuplpmStCost = ?"
                + ")";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stcKey);
            statement.setInt(2, stcKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private int findOrCreateRel(Connection connection, int parentKey, int childKey) throws SQLException {
        Integer existing = findRelKey(connection, parentKey, childKey);
        if (existing != null) {
            return existing;
        }
        String insert = "INSERT INTO " + q("stRel") + " (strParent, strChild) VALUES (?, ?)";
        try (PreparedStatement statement =
                     connection.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, parentKey);
            statement.setInt(2, childKey);
            statement.executeUpdate();
            return readGeneratedKey(statement, "strKey");
        }
    }

    private Integer findRelKey(Connection connection, int parentKey, int childKey) throws SQLException {
        String sql = "SELECT strKey FROM " + q("stRel") + " WHERE strParent = ? AND strChild = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, parentKey);
            statement.setInt(2, childKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return null;
                }
                return resultSet.getInt(1);
            }
        }
    }

    private int nextSiblingNum(Connection connection, int stNetKey, int parentKey) throws SQLException {
        String sql = ""
                + "SELECT ISNULL(MAX(p.stpnNum), 0) + 1 "
                + "FROM " + q("stNetPn") + " p "
                + "JOIN " + q("stRel") + " r ON r.strKey = p.stnpStRel "
                + "WHERE p.stpnStNet = ? AND r.strParent = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stNetKey);
            statement.setInt(2, parentKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                resultSet.next();
                return resultSet.getInt(1);
            }
        }
    }

    private boolean relUsedInAnyNet(Connection connection, int relKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("stNetPn") + " WHERE stnpStRel = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, relKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private boolean relInNetwork(Connection connection, int stNetKey, int relKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("stNetPn") + " WHERE stpnStNet = ? AND stnpStRel = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stNetKey);
            statement.setInt(2, relKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private boolean hasIpgStPn(Connection connection, int stiKey) throws SQLException {
        String sql = "SELECT 1 FROM " + q("ipgStPn") + " WHERE ipgspSt = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private boolean usedInOtherNetworks(Connection connection, int stiKey, int stNetKey) throws SQLException {
        String sql = ""
                + "SELECT 1 FROM " + q("stNetPn") + " p "
                + "JOIN " + q("stRel") + " r ON r.strKey = p.stnpStRel "
                + "WHERE p.stpnStNet <> ? AND (r.strChild = ? OR r.strParent = ?)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stNetKey);
            statement.setInt(2, stiKey);
            statement.setInt(3, stiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
    }

    private boolean hasChildrenInNetwork(Connection connection, int stNetKey, int stiKey) throws SQLException {
        String sql = ""
                + "SELECT 1 FROM " + q("stNetPn") + " p "
                + "JOIN " + q("stRel") + " r ON r.strKey = p.stnpStRel "
                + "WHERE p.stpnStNet = ? AND r.strParent = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stNetKey);
            statement.setInt(2, stiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        }
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
