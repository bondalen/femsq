package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RalpRa;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RalpRaDao} для {@code ags.ralpRa}.
 */
public class JdbcRalpRaDao implements RalpRaDao {

    private static final Logger log = Logger.getLogger(JdbcRalpRaDao.class.getName());
    private static final String COLUMNS =
            "r.ralprKey, r.ralprNum, r.ralprDate, r.ralprCstAgPn, r.ralprOgSender, "
                    + "COALESCE(og.ogNm, ogViaNmF.ogNm, "
                    + "NULLIF(LTRIM(RTRIM(CONCAT(nf.onfName, "
                    + "CASE WHEN NULLIF(LTRIM(RTRIM(nf.onfNameExt)), N'') IS NOT NULL "
                    + "THEN N', ' + LTRIM(RTRIM(nf.onfNameExt)) ELSE N'' END))), N'')) AS ogNm, "
                    + "r.ralprY, r.ralprM";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcRalpRaDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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

    private String table() {
        return schemaPrefix() + "ralpRa";
    }

    /**
     * SELECT с подписью отправителя: канон {@code og.ogKey}→{@code og.ogNm};
     * fallback legacy {@code ogNmF.onfKey}→{@code onfOg}→{@code og.ogNm} (dev-домен до 0054.7.4).
     */
    private String selectWithSenderLabel() {
        String p = schemaPrefix();
        return "SELECT " + COLUMNS
                + " FROM " + table() + " r "
                + "LEFT JOIN " + p + "og og ON og.ogKey = r.ralprOgSender "
                + "LEFT JOIN " + p + "ogNmF nf ON nf.onfKey = r.ralprOgSender "
                + "LEFT JOIN " + p + "og ogViaNmF ON ogViaNmF.ogKey = nf.onfOg";
    }

    @Override
    public Optional<RalpRa> findById(int ralprKey) {
        String sql = selectWithSenderLabel() + " WHERE r.ralprKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralprKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить отчёт аренды " + ralprKey, exception);
        }
    }

    @Override
    public RalpRa create(RalpRa report) {
        String sql = "INSERT INTO " + table()
                + " (ralprNum, ralprDate, ralprCstAgPn, ralprOgSender) VALUES (?, ?, ?, ?)";
        log.log(Level.INFO, "Creating ralpRa for cstAgPn={0}", report.ralprCstAgPn());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setNString(1, report.ralprNum());
            statement.setDate(2, Date.valueOf(report.ralprDate()));
            statement.setInt(3, report.ralprCstAgPn());
            statement.setInt(4, report.ralprOgSender());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не получен ralprKey после INSERT");
                }
                return findById(keys.getInt(1))
                        .orElseThrow(() -> new DaoException("Отчёт аренды не найден после INSERT"));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать отчёт аренды", exception);
        }
    }

    @Override
    public RalpRa update(RalpRa report) {
        Objects.requireNonNull(report.ralprKey(), "ralprKey");
        String sql = "UPDATE " + table()
                + " SET ralprNum = ?, ralprDate = ?, ralprCstAgPn = ?, ralprOgSender = ? "
                + "WHERE ralprKey = ?";
        log.log(Level.INFO, "Updating ralpRa ralprKey={0}", report.ralprKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, report.ralprNum());
            statement.setDate(2, Date.valueOf(report.ralprDate()));
            statement.setInt(3, report.ralprCstAgPn());
            statement.setInt(4, report.ralprOgSender());
            statement.setInt(5, report.ralprKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("Отчёт аренды " + report.ralprKey() + " не найден для обновления");
            }
            return findById(report.ralprKey()).orElseThrow();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить отчёт аренды " + report.ralprKey(), exception);
        }
    }

    @Override
    public boolean deleteById(int ralprKey) {
        String sql = "DELETE FROM " + table() + " WHERE ralprKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralprKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить отчёт аренды " + ralprKey, exception);
        }
    }

    @Override
    public boolean hasAus(int ralprKey) {
        String sql = "SELECT TOP 1 1 FROM " + schemaPrefix() + "ralpRaAu WHERE ralpraRa = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralprKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось проверить строки Au отчёта " + ralprKey, exception);
        }
    }

    private RalpRa mapRow(ResultSet resultSet) throws SQLException {
        return new RalpRa(
                resultSet.getInt("ralprKey"),
                resultSet.getNString("ralprNum"),
                toLocalDate(resultSet.getDate("ralprDate")),
                resultSet.getInt("ralprCstAgPn"),
                resultSet.getInt("ralprOgSender"),
                resultSet.getString("ogNm"),
                getInteger(resultSet, "ralprY"),
                getInteger(resultSet, "ralprM")
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
