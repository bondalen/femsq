package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAg;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CstAgDao}.
 */
public class JdbcCstAgDao implements CstAgDao {

    private static final Logger log = Logger.getLogger(JdbcCstAgDao.class.getName());
    private static final String TABLE_BASE_NAME = "cstAg";
    private static final String LOOKUP_BASE_NAME = "ogAgCs";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCstAgDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                log.log(Level.WARNING, "Schema not configured, using default schema 'ags'");
                return "ags.";
            }
            return schema + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema", exception);
            return "ags_test.";
        }
    }

    private String getTableName() {
        return schemaPrefix() + TABLE_BASE_NAME;
    }

    private String getLookupTableName() {
        return schemaPrefix() + LOOKUP_BASE_NAME;
    }

    @Override
    public Optional<CstAg> findById(int cstaKey) {
        String sql = selectWithLabel() + " WHERE a.cstaKey = ?";
        log.log(Level.FINE, "Executing findById for cstaKey={0}", cstaKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstaKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById for cstAg", exception);
            throw new DaoException("Не удалось получить агента стройки с идентификатором " + cstaKey, exception);
        }
    }

    @Override
    public List<CstAg> findByCst(int cstKey) {
        String sql = selectWithLabel() + " WHERE a.cstaCst = ? ORDER BY l.ogaNm, a.cstaKey";
        log.log(Level.FINE, "Executing findByCst for cstKey={0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstAg> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByCst for cstAg", exception);
            throw new DaoException("Не удалось получить агентов стройки " + cstKey, exception);
        }
    }

    @Override
    public CstAg create(CstAg agent) {
        Objects.requireNonNull(agent, "agent");
        String sql = "INSERT INTO " + getTableName() + " (cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (?, ?, ?, ?)";
        log.log(Level.INFO, "Creating cstAg for cst={0}, ag={1}", new Object[]{agent.cstaCst(), agent.cstaAg()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, agent);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int id = generatedKeys.getInt(1);
                    return findById(id).orElseThrow(() -> new DaoException("Не удалось прочитать созданную запись cstAg " + id));
                }
                throw new DaoException("Не удалось получить идентификатор созданной записи cstAg");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create for cstAg", exception);
            throw new DaoException("Не удалось создать агента стройки", exception);
        }
    }

    @Override
    public CstAg update(CstAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.cstaKey() == null) {
            throw new DaoException("Для обновления cstAg необходим идентификатор");
        }
        String sql = "UPDATE " + getTableName()
                + " SET cstaAg = ?, cstaCst = ?, cstaOidOld = ?, cstaInvestor = ? WHERE cstaKey = ?";
        log.log(Level.INFO, "Updating cstAg {0}", agent.cstaKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, agent);
            statement.setInt(5, agent.cstaKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Агент стройки с идентификатором " + agent.cstaKey() + " не найден");
            }
            return findById(agent.cstaKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённую запись cstAg " + agent.cstaKey()));
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update for cstAg", exception);
            throw new DaoException("Не удалось обновить агента стройки", exception);
        }
    }

    @Override
    public boolean deleteById(int cstaKey) {
        String sql = "DELETE FROM " + getTableName() + " WHERE cstaKey = ?";
        log.log(Level.INFO, "Deleting cstAg {0}", cstaKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstaKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete for cstAg", exception);
            throw new DaoException("Не удалось удалить агента стройки " + cstaKey, exception);
        }
    }

    private String selectWithLabel() {
        return "SELECT a.cstaKey, a.cstaAg, a.cstaCst, a.cstaOidOld, a.cstaInvestor, l.ogaNm AS agentLabel "
                + "FROM " + getTableName() + " a "
                + "LEFT JOIN " + getLookupTableName() + " l ON l.ogaKey = a.cstaAg";
    }

    private void bindMutable(PreparedStatement statement, CstAg agent) throws SQLException {
        statement.setInt(1, agent.cstaAg());
        statement.setInt(2, agent.cstaCst());
        if (agent.cstaOidOld() == null) {
            statement.setNull(3, Types.OTHER);
        } else {
            statement.setObject(3, agent.cstaOidOld());
        }
        if (agent.cstaInvestor() == null) {
            statement.setNull(4, Types.INTEGER);
        } else {
            statement.setInt(4, agent.cstaInvestor());
        }
    }

    private CstAg mapRow(ResultSet resultSet) throws SQLException {
        return new CstAg(
                resultSet.getInt("cstaKey"),
                resultSet.getInt("cstaAg"),
                resultSet.getInt("cstaCst"),
                resultSet.getObject("cstaOidOld", UUID.class),
                resultSet.getObject("cstaInvestor", Integer.class),
                resultSet.getNString("agentLabel")
        );
    }
}
