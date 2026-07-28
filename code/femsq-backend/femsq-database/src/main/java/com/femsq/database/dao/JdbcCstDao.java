package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Cst;
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
 * JDBC-реализация {@link CstDao}.
 */
public class JdbcCstDao implements CstDao {

    private static final Logger log = Logger.getLogger(JdbcCstDao.class.getName());
    private static final String TABLE_BASE_NAME = "cst";
    private static final String COLUMNS = "cstKey, cstName, cstBusSgm, cstOidOld, cstMark";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCstDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String getTableName() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                log.log(Level.WARNING, "Schema not configured, using default schema 'ags'");
                return "ags." + TABLE_BASE_NAME;
            }
            return schema + "." + TABLE_BASE_NAME;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema", exception);
            return "ags_test." + TABLE_BASE_NAME;
        }
    }

    @Override
    public Optional<Cst> findById(int cstKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + getTableName() + " WHERE cstKey = ?";
        log.log(Level.FINE, "Executing findById for cstKey={0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById for cst", exception);
            throw new DaoException("Не удалось получить стройку с идентификатором " + cstKey, exception);
        }
    }

    @Override
    public List<Cst> findAll() {
        String sql = "SELECT " + COLUMNS + " FROM " + getTableName() + " ORDER BY cstName";
        log.fine("Executing findAll for cst");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<Cst> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRow(resultSet));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll for cst", exception);
            throw new DaoException("Не удалось получить список строек", exception);
        }
    }

    @Override
    public Cst create(Cst site) {
        Objects.requireNonNull(site, "site");
        String sql = "INSERT INTO " + getTableName() + " (cstName, cstBusSgm, cstOidOld, cstMark) VALUES (?, ?, ?, ?)";
        log.log(Level.INFO, "Creating construction site {0}", site.cstName());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, site);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    return withId(site, generatedKeys.getInt(1));
                }
                throw new DaoException("Не удалось получить идентификатор созданной стройки");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create for cst", exception);
            throw new DaoException("Не удалось создать стройку", exception);
        }
    }

    @Override
    public Cst update(Cst site) {
        Objects.requireNonNull(site, "site");
        if (site.cstKey() == null) {
            throw new DaoException("Для обновления стройки необходим идентификатор");
        }
        String sql = "UPDATE " + getTableName()
                + " SET cstName = ?, cstBusSgm = ?, cstOidOld = ?, cstMark = ? WHERE cstKey = ?";
        log.log(Level.INFO, "Updating construction site {0}", site.cstKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, site);
            statement.setInt(5, site.cstKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Стройка с идентификатором " + site.cstKey() + " не найдена");
            }
            return site;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update for cst", exception);
            throw new DaoException("Не удалось обновить стройку", exception);
        }
    }

    @Override
    public boolean deleteById(int cstKey) {
        String sql = "DELETE FROM " + getTableName() + " WHERE cstKey = ?";
        log.log(Level.INFO, "Deleting construction site {0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete for cst", exception);
            throw new DaoException("Не удалось удалить стройку " + cstKey, exception);
        }
    }

    private void bindMutable(PreparedStatement statement, Cst site) throws SQLException {
        statement.setNString(1, site.cstName());
        statement.setNString(2, site.cstBusSgm());
        if (site.cstOidOld() == null) {
            statement.setNull(3, Types.OTHER);
        } else {
            statement.setObject(3, site.cstOidOld());
        }
        if (site.cstMark() == null) {
            statement.setNull(4, Types.INTEGER);
        } else {
            statement.setInt(4, site.cstMark());
        }
    }

    private Cst mapRow(ResultSet resultSet) throws SQLException {
        return new Cst(
                resultSet.getInt("cstKey"),
                resultSet.getNString("cstName"),
                resultSet.getNString("cstBusSgm"),
                resultSet.getObject("cstOidOld", UUID.class),
                resultSet.getObject("cstMark", Integer.class)
        );
    }

    private Cst withId(Cst site, int generatedId) {
        return new Cst(generatedId, site.cstName(), site.cstBusSgm(), site.cstOidOld(), site.cstMark());
    }
}
