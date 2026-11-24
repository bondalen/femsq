package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStagingDraft;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link ImpIpgLoadDao} (C2 §3.1.6.1).
 */
public class JdbcImpIpgLoadDao implements ImpIpgLoadDao {

    private static final Logger log = Logger.getLogger(JdbcImpIpgLoadDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcImpIpgLoadDao(
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
    public Optional<ImpIpgLoad> findLoadByKey(int iilKey) {
        String sql = "SELECT iilKey, iilIpg, iilNm, iilFilePath, iilNote, iilCreated FROM "
                + q("impIpgLoad") + " WHERE iilKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iilKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapLoad(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpgLoad=" + iilKey, exception);
        }
    }

    @Override
    public List<ImpIpgLoad> findLoadsByIpg(int ipgKey) {
        String sql = "SELECT iilKey, iilIpg, iilNm, iilFilePath, iilNote, iilCreated FROM "
                + q("impIpgLoad") + " WHERE iilIpg = ? ORDER BY iilKey DESC";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<ImpIpgLoad> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(mapLoad(resultSet));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpgLoad по ipg=" + ipgKey, exception);
        }
    }

    @Override
    public ImpIpgLoad insertLoad(int ipgKey, String name, String filePath, String note) {
        String sql = "INSERT INTO " + q("impIpgLoad")
                + " (iilIpg, iilNm, iilFilePath, iilNote) VALUES (?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, ipgKey);
            statement.setString(2, name);
            setNullableString(statement, 3, filePath);
            setNullableString(statement, 4, note);
            statement.executeUpdate();
            int key = readGeneratedKey(statement);
            log.info(() -> "insertLoad iilKey=" + key + " ipg=" + ipgKey);
            return findLoadByKey(key).orElseThrow(() -> new DaoException("impIpgLoad не найден после insert: " + key));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать impIpgLoad для ipg=" + ipgKey, exception);
        }
    }

    @Override
    public ImpIpgLoad updateLoad(int iilKey, String name, String filePath, String note) {
        String sql = "UPDATE " + q("impIpgLoad")
                + " SET iilNm = ?, iilFilePath = ?, iilNote = ? WHERE iilKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, name);
            setNullableString(statement, 2, filePath);
            setNullableString(statement, 3, note);
            statement.setInt(4, iilKey);
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("impIpgLoad не найден: " + iilKey);
            }
            return findLoadByKey(iilKey).orElseThrow(() -> new DaoException("impIpgLoad пропал после update: " + iilKey));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить impIpgLoad=" + iilKey, exception);
        }
    }

    @Override
    public boolean deleteLoad(int iilKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                deleteRowsByLoad(connection, iilKey);
                String sql = "DELETE FROM " + q("impIpgLoad") + " WHERE iilKey = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setInt(1, iilKey);
                    int deleted = statement.executeUpdate();
                    connection.commit();
                    log.info(() -> "deleteLoad iilKey=" + iilKey + " deleted=" + deleted);
                    return deleted > 0;
                }
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить impIpgLoad=" + iilKey, exception);
        }
    }

    @Override
    public Optional<ImpIpgRow> findRowByKey(int iiKey) {
        String sql = rowSelect() + " WHERE iiKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iiKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRow(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpg=" + iiKey, exception);
        }
    }

    @Override
    public List<ImpIpgRow> findRowsByLoad(int iilKey) {
        return findRows(iilKey, false);
    }

    @Override
    public List<ImpIpgRow> findStructureRowsByLoad(int iilKey) {
        return findRows(iilKey, true);
    }

    private List<ImpIpgRow> findRows(int iilKey, boolean structureOnly) {
        String sql = rowSelect() + " WHERE iiLoad = ?"
                + (structureOnly ? " AND iiRowKind = 'S'" : "")
                + " ORDER BY iiRowNo, iiKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iilKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<ImpIpgRow> rows = new ArrayList<>();
                while (resultSet.next()) {
                    rows.add(mapRow(resultSet));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpg по load=" + iilKey, exception);
        }
    }

    @Override
    public ImpIpgRow insertRow(
            int loadKey,
            int rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx) {
        validateRowKind(rowKind);
        String sql = "INSERT INTO " + q("impIpg")
                + " (iiLoad, iiRowNo, iiRowKind, iiText, iiParent, iiStiKey, iiCtx)"
                + " VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, loadKey);
            statement.setInt(2, rowNo);
            statement.setString(3, rowKind.trim().toUpperCase());
            setNullableString(statement, 4, text);
            setNullableInt(statement, 5, parentKey);
            setNullableInt(statement, 6, stiKey);
            setNullableString(statement, 7, ctx);
            statement.executeUpdate();
            int key = readGeneratedKey(statement);
            return findRowByKey(key).orElseThrow(() -> new DaoException("impIpg не найден после insert: " + key));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать строку impIpg load=" + loadKey, exception);
        }
    }

    @Override
    public ImpIpgRow updateRow(
            int iiKey,
            Integer rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx) {
        ImpIpgRow current = findRowByKey(iiKey)
                .orElseThrow(() -> new DaoException("impIpg не найден: " + iiKey));
        String kind = rowKind != null ? rowKind.trim().toUpperCase() : current.iiRowKind();
        validateRowKind(kind);
        String sql = "UPDATE " + q("impIpg")
                + " SET iiRowNo = ?, iiRowKind = ?, iiText = ?, iiParent = ?, iiStiKey = ?, iiCtx = ?"
                + " WHERE iiKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, rowNo != null ? rowNo : current.iiRowNo());
            statement.setString(2, kind);
            setNullableString(statement, 3, text != null ? text : current.iiText());
            setNullableInt(statement, 4, parentKey != null ? parentKey : current.iiParent());
            // stiKey передаётся уже разрешённым сервисом (включая null = сброс).
            setNullableInt(statement, 5, stiKey);
            setNullableString(statement, 6, ctx != null ? ctx : current.iiCtx());
            statement.setInt(7, iiKey);
            statement.executeUpdate();
            return findRowByKey(iiKey).orElseThrow(() -> new DaoException("impIpg пропал после update: " + iiKey));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить impIpg=" + iiKey, exception);
        }
    }

    @Override
    public boolean deleteRow(int iiKey) {
        String sql = "DELETE FROM " + q("impIpg") + " WHERE iiKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iiKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить impIpg=" + iiKey, exception);
        }
    }

    @Override
    public int deleteRowsByLoad(int iilKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            return deleteRowsByLoad(connection, iilKey);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось очистить impIpg load=" + iilKey, exception);
        }
    }

    @Override
    public int replaceRows(int iilKey, List<ImpIpgStagingDraft> drafts) {
        Objects.requireNonNull(drafts, "drafts");
        if (!findLoadByKey(iilKey).isPresent()) {
            throw new DaoException("impIpgLoad не найден: " + iilKey);
        }
        String insertSql = "INSERT INTO " + q("impIpg")
                + " (iiLoad, iiRowNo, iiRowKind, iiText, iiParent, iiStiKey, iiCtx)"
                + " VALUES (?, ?, ?, ?, ?, NULL, ?)";
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                deleteRowsByLoad(connection, iilKey);
                Map<Integer, Integer> indexToKey = new HashMap<>();
                try (PreparedStatement statement =
                        connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    for (int index = 0; index < drafts.size(); index++) {
                        ImpIpgStagingDraft draft = drafts.get(index);
                        validateRowKind(draft.rowKind());
                        Integer parentKey = null;
                        if (draft.parentIndex() != null) {
                            parentKey = indexToKey.get(draft.parentIndex());
                            if (parentKey == null) {
                                throw new DaoException(
                                        "parentIndex=" + draft.parentIndex()
                                                + " не резолвится для строки #" + index);
                            }
                        }
                        statement.setInt(1, iilKey);
                        statement.setInt(2, draft.rowNo());
                        statement.setString(3, draft.rowKind().trim().toUpperCase());
                        setNullableString(statement, 4, draft.text());
                        setNullableInt(statement, 5, parentKey);
                        setNullableString(statement, 6, draft.ctx());
                        statement.executeUpdate();
                        int key = readGeneratedKey(statement);
                        indexToKey.put(index, key);
                    }
                }
                connection.commit();
                log.info(() -> "replaceRows load=" + iilKey + " count=" + drafts.size());
                return drafts.size();
            } catch (SQLException | DaoException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (DaoException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось заменить staging load=" + iilKey, exception);
        }
    }

    private int deleteRowsByLoad(Connection connection, int iilKey) throws SQLException {
        // Сначала обнулить parent, затем удалить (избегаем FK self-ref)
        String clearParent = "UPDATE " + q("impIpg") + " SET iiParent = NULL WHERE iiLoad = ?";
        try (PreparedStatement statement = connection.prepareStatement(clearParent)) {
            statement.setInt(1, iilKey);
            statement.executeUpdate();
        }
        String delete = "DELETE FROM " + q("impIpg") + " WHERE iiLoad = ?";
        try (PreparedStatement statement = connection.prepareStatement(delete)) {
            statement.setInt(1, iilKey);
            return statement.executeUpdate();
        }
    }

    private String rowSelect() {
        return "SELECT iiKey, iiLoad, iiRowNo, iiRowKind, iiText, iiParent, iiStiKey, iiCtx FROM "
                + q("impIpg");
    }

    private static ImpIpgLoad mapLoad(ResultSet resultSet) throws SQLException {
        Timestamp created = resultSet.getTimestamp("iilCreated");
        LocalDateTime createdAt = created != null ? created.toLocalDateTime() : null;
        return new ImpIpgLoad(
                resultSet.getInt("iilKey"),
                resultSet.getInt("iilIpg"),
                resultSet.getString("iilNm"),
                resultSet.getString("iilFilePath"),
                resultSet.getString("iilNote"),
                createdAt);
    }

    private static ImpIpgRow mapRow(ResultSet resultSet) throws SQLException {
        int parent = resultSet.getInt("iiParent");
        Integer parentKey = resultSet.wasNull() ? null : parent;
        int sti = resultSet.getInt("iiStiKey");
        Integer stiKey = resultSet.wasNull() ? null : sti;
        return new ImpIpgRow(
                resultSet.getInt("iiKey"),
                resultSet.getInt("iiLoad"),
                resultSet.getInt("iiRowNo"),
                resultSet.getString("iiRowKind"),
                resultSet.getString("iiText"),
                parentKey,
                stiKey,
                resultSet.getString("iiCtx"));
    }

    private static void validateRowKind(String rowKind) {
        if (rowKind == null || rowKind.isBlank()) {
            throw new DaoException("iiRowKind обязателен (S|L)");
        }
        String kind = rowKind.trim().toUpperCase();
        if (!"S".equals(kind) && !"L".equals(kind)) {
            throw new DaoException("iiRowKind должен быть S или L: " + rowKind);
        }
    }

    private static int readGeneratedKey(PreparedStatement statement) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (!keys.next()) {
                throw new DaoException("IDENTITY key не получен");
            }
            return keys.getInt(1);
        }
    }

    private static void setNullableString(PreparedStatement statement, int index, String value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setString(index, value);
        }
    }

    private static void setNullableInt(PreparedStatement statement, int index, Integer value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.INTEGER);
        } else {
            statement.setInt(index, value);
        }
    }
}
