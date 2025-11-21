package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.InvestmentPlanGroup;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/** JDBC-реализация {@link InvestmentPlanGroupDao}. */
public class JdbcInvestmentPlanGroupDao implements InvestmentPlanGroupDao {

    private static final Logger log = Logger.getLogger(JdbcInvestmentPlanGroupDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcInvestmentPlanGroupDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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

    @Override
    public List<InvestmentPlanGroup> findAllWithDisplayName() {
        String schema = resolveSchema();
        String sql = "SELECT upl.iuplgKey, " +
                "CONCAT(yy.yyyy, '. ', ipg.ipgNum, ' ', ipg.ipgNm, '. ', upl.iuplgNm) AS name " +
                "FROM " + schema + ".ipgUtPlGr AS upl " +
                "INNER JOIN " + schema + ".ipg AS ipg ON upl.iuplgIpg = ipg.ipgKey " +
                "INNER JOIN " + schema + ".yyyy AS yy ON ipg.ipgYy = yy.yKey " +
                "ORDER BY yy.yyyy, ipg.ipgNum, ipg.ipgNm, upl.iuplgNm";

        log.fine("Executing findAllWithDisplayName for plan groups");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<InvestmentPlanGroup> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(new InvestmentPlanGroup(
                        resultSet.getInt("iuplgKey"),
                        resultSet.getNString("name")
                ));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAllWithDisplayName for plan groups", exception);
            throw new DaoException("Не удалось получить список групп планов", exception);
        }
    }
}
