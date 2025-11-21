package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.InvestmentProgram;
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
 * JDBC-реализация {@link InvestmentProgramDao}.
 * Формирует отформатированное название из {@code ags.ipg}, {@code ags.og}, {@code ags.yyyy}.
 */
public class JdbcInvestmentProgramDao implements InvestmentProgramDao {

    private static final Logger log = Logger.getLogger(JdbcInvestmentProgramDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcInvestmentProgramDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
    public List<InvestmentProgram> findAllWithDisplayName() {
        String schema = resolveSchema();
        // Формируем отформатированное название: "Организация, Год № Номер. Название; с дата по дата"
        String sql = "SELECT ipg.ipgKey, " +
                "CONCAT(og.ogNm, ', ', yy.yyyy, ' № ', ipg.ipgNum, '. ', ipg.ipgNm, " +
                "CASE WHEN ipg.ipgStr IS NULL THEN '' ELSE CONCAT('; с ', CONVERT(varchar(10), ipg.ipgStr, 104)) END, " +
                "CASE WHEN ipg.ipgEnd IS NULL THEN '' ELSE CONCAT(' по ', CONVERT(varchar(10), ipg.ipgEnd, 104)) END" +
                ") AS name " +
                "FROM " + schema + ".ipg AS ipg " +
                "INNER JOIN " + schema + ".og AS og ON ipg.ipgOg = og.ogKey " +
                "INNER JOIN " + schema + ".yyyy AS yy ON ipg.ipgYy = yy.yKey " +
                "ORDER BY og.ogNm, yy.yyyy, ipg.ipgNum, ipg.ipgNm";

        log.fine("Executing findAllWithDisplayName for investment programs");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<InvestmentProgram> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(new InvestmentProgram(
                        resultSet.getInt("ipgKey"),
                        resultSet.getNString("name")
                ));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAllWithDisplayName", exception);
            throw new DaoException("Не удалось получить список инвестиционных программ", exception);
        }
    }
}
