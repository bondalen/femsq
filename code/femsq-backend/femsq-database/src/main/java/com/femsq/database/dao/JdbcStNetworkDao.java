package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.StNetwork;
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
 * JDBC-реализация {@link StNetworkDao}.
 */
public class JdbcStNetworkDao implements StNetworkDao {

    private static final Logger log = Logger.getLogger(JdbcStNetworkDao.class.getName());
    private static final String TABLE_BASE_NAME = "stNet";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcStNetworkDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String resolveSchema() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                log.log(Level.WARNING, "Schema not configured, using default schema 'ags'");
                return "ags";
            }
            return schema.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema 'ags'", exception);
            return "ags";
        }
    }

    private String getTableName() {
        return resolveSchema() + "." + TABLE_BASE_NAME;
    }

    @Override
    public List<StNetwork> findAllOrdered() {
        String sql = "SELECT stnKey, stnName FROM " + getTableName() + " ORDER BY stnName";
        log.fine("Executing findAllOrdered for stNet");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<StNetwork> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(new StNetwork(
                        resultSet.getInt("stnKey"),
                        resultSet.getNString("stnName")
                ));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAllOrdered", exception);
            throw new DaoException("Не удалось получить список структур сети", exception);
        }
    }
}
