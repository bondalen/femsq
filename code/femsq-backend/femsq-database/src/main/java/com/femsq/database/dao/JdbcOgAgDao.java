package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.OgAg;
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
 * JDBC-реализация {@link OgAgDao} на основе {@link ConnectionFactory}.
 */
public class JdbcOgAgDao implements OgAgDao {

    private static final Logger log = Logger.getLogger(JdbcOgAgDao.class.getName());
    private static final String TABLE_NAME = "ags_test.ogAg";

    private final ConnectionFactory connectionFactory;

    public JdbcOgAgDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<OgAg> findById(int ogAgKey) {
        String sql = "SELECT ogaKey, ogaCode, ogaOg, ogaOidOld FROM " + TABLE_NAME + " WHERE ogaKey = ?";
        log.log(Level.FINE, "Executing findById for ogAgKey={0}", ogAgKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ogAgKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapOgAg(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById for ogAg", exception);
            throw new DaoException("Не удалось получить агентскую организацию с идентификатором " + ogAgKey, exception);
        }
    }

    @Override
    public List<OgAg> findByOrganization(int organizationKey) {
        String sql = "SELECT ogaKey, ogaCode, ogaOg, ogaOidOld FROM " + TABLE_NAME + " WHERE ogaOg = ? ORDER BY ogaKey";
        log.log(Level.FINE, "Executing findByOrganization for ogKey={0}", organizationKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, organizationKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<OgAg> agents = new ArrayList<>();
                while (resultSet.next()) {
                    agents.add(mapOgAg(resultSet));
                }
                return List.copyOf(agents);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByOrganization", exception);
            throw new DaoException("Не удалось получить агентские организации для организации " + organizationKey, exception);
        }
    }

    @Override
    public List<OgAg> findAll() {
        String sql = "SELECT ogaKey, ogaCode, ogaOg, ogaOidOld FROM " + TABLE_NAME + " ORDER BY ogaKey";
        log.fine("Executing findAll for ogAg");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<OgAg> agents = new ArrayList<>();
            while (resultSet.next()) {
                agents.add(mapOgAg(resultSet));
            }
            return List.copyOf(agents);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll for ogAg", exception);
            throw new DaoException("Не удалось получить список агентских организаций", exception);
        }
    }

    @Override
    public OgAg create(OgAg agent) {
        Objects.requireNonNull(agent, "agent");
        String sql = "INSERT INTO " + TABLE_NAME + " (ogaCode, ogaOg, ogaOidOld) VALUES (?, ?, ?)";
        log.log(Level.INFO, "Creating agent for organization {0}", agent.organizationKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindAgent(statement, agent);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int generatedId = generatedKeys.getInt(1);
                    return agentWithId(agent, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданной записи ogAg");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create for ogAg", exception);
            throw new DaoException("Не удалось создать агентскую организацию", exception);
        }
    }

    @Override
    public OgAg update(OgAg agent) {
        Objects.requireNonNull(agent, "agent");
        if (agent.ogAgKey() == null) {
            throw new DaoException("Для обновления агентской организации необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME + " SET ogaCode = ?, ogaOg = ?, ogaOidOld = ? WHERE ogaKey = ?";
        log.log(Level.INFO, "Updating agent {0}", agent.ogAgKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindAgent(statement, agent);
            statement.setInt(4, agent.ogAgKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Агентская организация с идентификатором " + agent.ogAgKey() + " не найдена");
            }
            return agent;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update for ogAg", exception);
            throw new DaoException("Не удалось обновить агентскую организацию", exception);
        }
    }

    @Override
    public boolean deleteById(int ogAgKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE ogaKey = ?";
        log.log(Level.INFO, "Deleting agent {0}", ogAgKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ogAgKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete for ogAg", exception);
            throw new DaoException("Не удалось удалить агентскую организацию " + ogAgKey, exception);
        }
    }

    private void bindAgent(PreparedStatement statement, OgAg agent) throws SQLException {
        statement.setNString(1, agent.code());
        statement.setInt(2, agent.organizationKey());
        if (agent.legacyOid() == null) {
            statement.setNull(3, Types.OTHER);
        } else {
            statement.setObject(3, agent.legacyOid());
        }
    }

    private OgAg mapOgAg(ResultSet resultSet) throws SQLException {
        UUID legacyOid = resultSet.getObject("ogaOidOld", UUID.class);
        return new OgAg(
                resultSet.getInt("ogaKey"),
                resultSet.getNString("ogaCode"),
                resultSet.getInt("ogaOg"),
                legacyOid
        );
    }

    private OgAg agentWithId(OgAg agent, int generatedId) {
        return new OgAg(
                generatedId,
                agent.code(),
                agent.organizationKey(),
                agent.legacyOid()
        );
    }
}
