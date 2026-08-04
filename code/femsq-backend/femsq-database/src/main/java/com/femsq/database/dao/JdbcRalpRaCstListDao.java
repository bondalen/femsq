package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RalpRaCstListEntry;
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
 * JDBC-реализация списка Access {@code ralpRaCst} через JOIN.
 *
 * <p>Подпись отправителя: {@code COALESCE(og.ogNm, …)} при {@code ralprOgSender = og.ogKey} (канон);
 * fallback по {@code ogNmF.onfKey} для legacy-строк до remap 0054.7.4.
 */
public class JdbcRalpRaCstListDao implements RalpRaCstListDao {

    private static final Logger log = Logger.getLogger(JdbcRalpRaCstListDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcRalpRaCstListDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
    public List<RalpRaCstListEntry> findByCst(int cstKey) {
        String p = schemaPrefix();
        String sql = "SELECT ca.cstaCst AS cstKey, ag.ogaNm, p.cstapIpgPnN, "
                + "r.ralprKey, r.ralprNum, r.ralprDate, r.ralprCstAgPn, r.ralprOgSender, "
                + "COALESCE(og.ogNm, ogViaNmF.ogNm, "
                + "NULLIF(LTRIM(RTRIM(CONCAT(nf.onfName, "
                + "CASE WHEN NULLIF(LTRIM(RTRIM(nf.onfNameExt)), N'') IS NOT NULL "
                + "THEN N', ' + LTRIM(RTRIM(nf.onfNameExt)) ELSE N'' END))), N'')) AS ogNm, "
                + "ISNULL(au.auCnt, 0) AS auCnt, "
                + "CAST(CASE WHEN ISNULL(au.returnedCnt, 0) > 0 THEN 1 ELSE 0 END AS bit) AS hasReturned "
                + "FROM " + p + "ralpRa r "
                + "INNER JOIN " + p + "cstAgPn p ON p.cstapKey = r.ralprCstAgPn "
                + "INNER JOIN " + p + "cstAg ca ON ca.cstaKey = p.cstapCsta "
                + "LEFT JOIN " + p + "og og ON og.ogKey = r.ralprOgSender "
                + "LEFT JOIN " + p + "ogNmF nf ON nf.onfKey = r.ralprOgSender "
                + "LEFT JOIN " + p + "og ogViaNmF ON ogViaNmF.ogKey = nf.onfOg "
                + "LEFT JOIN " + p + "ogAgCs ag ON ag.ogaKey = ca.cstaAg "
                + "LEFT JOIN ("
                + "  SELECT ralpraRa, COUNT(*) AS auCnt, "
                + "    SUM(CASE WHEN ralpraStatus = 3 "
                + "      OR (ralpraReturned IS NOT NULL AND LTRIM(RTRIM(ralpraReturned)) <> N'') "
                + "      THEN 1 ELSE 0 END) AS returnedCnt "
                + "  FROM " + p + "ralpRaAu GROUP BY ralpraRa"
                + ") au ON au.ralpraRa = r.ralprKey "
                + "WHERE ca.cstaCst = ? "
                + "ORDER BY r.ralprDate DESC, r.ralprKey";
        log.log(Level.FINE, "ralpRaCst list for cstKey={0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RalpRaCstListEntry> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed ralpRaCst list for cstKey=" + cstKey, exception);
            throw new DaoException("Не удалось получить отчёты аренды для стройки " + cstKey, exception);
        }
    }

    private RalpRaCstListEntry mapRow(ResultSet resultSet) throws SQLException {
        return new RalpRaCstListEntry(
                getInteger(resultSet, "cstKey"),
                resultSet.getString("ogaNm"),
                resultSet.getString("cstapIpgPnN"),
                resultSet.getInt("ralprKey"),
                resultSet.getString("ralprNum"),
                toLocalDate(resultSet.getDate("ralprDate")),
                getInteger(resultSet, "ralprCstAgPn"),
                getInteger(resultSet, "ralprOgSender"),
                resultSet.getString("ogNm"),
                resultSet.getInt("auCnt"),
                resultSet.getBoolean("hasReturned")
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
