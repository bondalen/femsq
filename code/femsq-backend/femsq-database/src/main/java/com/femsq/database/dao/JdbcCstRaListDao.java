package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstRaListEntry;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CstRaListDao} через TVF {@code ags.fnRRcList}.
 */
public class JdbcCstRaListDao implements CstRaListDao {

    private static final Logger log = Logger.getLogger(JdbcCstRaListDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCstRaListDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                return "ags.";
            }
            return schema + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema", exception);
            return "ags_test.";
        }
    }

    @Override
    public List<CstRaListEntry> findByCst(int cstKey) {
        String sql = "SELECT yyyy, mNum, p, cstaKey, cstaAg, cstaCst, ogaNm, cstapKey, cstapIpgPnN, "
                + "ra_key, ra_num, ra_date, ra_type, raChKey, raChNum, raChDate, "
                + "ra_org_sender, ogNm, ras_total, ras_work, ras_equip, ras_others, "
                + "ra_arrived, ra_arrived_date, ra_returned, ra_returned_date, ra_sent, ra_sent_date "
                + "FROM " + schemaPrefix() + "fnRRcList(?) "
                + "ORDER BY yyyy, mNum, ra_num, raChKey";
        log.log(Level.FINE, "Executing fnRRcList for cstKey={0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstRaListEntry> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute fnRRcList for cstKey=" + cstKey, exception);
            throw new DaoException("Не удалось получить перечень отчётов для стройки " + cstKey, exception);
        }
    }

    private CstRaListEntry mapRow(ResultSet resultSet) throws SQLException {
        return new CstRaListEntry(
                getInteger(resultSet, "yyyy"),
                getInteger(resultSet, "mNum"),
                resultSet.getString("p"),
                getInteger(resultSet, "cstaKey"),
                getInteger(resultSet, "cstaAg"),
                getInteger(resultSet, "cstaCst"),
                resultSet.getString("ogaNm"),
                getInteger(resultSet, "cstapKey"),
                resultSet.getString("cstapIpgPnN"),
                Objects.requireNonNull(getInteger(resultSet, "ra_key"), "ra_key"),
                resultSet.getString("ra_num"),
                toLocalDate(resultSet.getDate("ra_date")),
                resultSet.getString("ra_type"),
                getInteger(resultSet, "raChKey"),
                resultSet.getString("raChNum"),
                toLocalDate(resultSet.getDate("raChDate")),
                getInteger(resultSet, "ra_org_sender"),
                resultSet.getString("ogNm"),
                resultSet.getBigDecimal("ras_total"),
                resultSet.getBigDecimal("ras_work"),
                resultSet.getBigDecimal("ras_equip"),
                resultSet.getBigDecimal("ras_others"),
                resultSet.getString("ra_arrived"),
                toLocalDate(resultSet.getDate("ra_arrived_date")),
                resultSet.getString("ra_returned"),
                toLocalDate(resultSet.getDate("ra_returned_date")),
                resultSet.getString("ra_sent"),
                toLocalDate(resultSet.getDate("ra_sent_date"))
        );
    }

    private static Integer getInteger(ResultSet resultSet, String column) throws SQLException {
        int value = resultSet.getInt(column);
        return resultSet.wasNull() ? null : value;
    }

    private static LocalDate toLocalDate(Date date) {
        return date == null ? null : date.toLocalDate();
    }
}
