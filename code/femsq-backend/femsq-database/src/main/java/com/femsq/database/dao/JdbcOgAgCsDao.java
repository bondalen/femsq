package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.OgAgCs;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link OgAgCsDao} для представления {@code ags.ogAgCs}.
 */
public class JdbcOgAgCsDao implements OgAgCsDao {

    private static final Logger log = Logger.getLogger(JdbcOgAgCsDao.class.getName());
    private static final String TABLE_BASE_NAME = "ogAgCs";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcOgAgCsDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
    public List<OgAgCs> findAll() {
        String sql = "SELECT ogaKey, ogaNm FROM " + getTableName() + " ORDER BY ogaNm";
        log.fine("Executing findAll for ogAgCs");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<OgAgCs> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(new OgAgCs(resultSet.getInt("ogaKey"), resultSet.getNString("ogaNm")));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll for ogAgCs", exception);
            throw new DaoException("Не удалось получить список агентов (ogAgCs)", exception);
        }
    }
}
