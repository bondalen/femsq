package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaReport;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaReportDao} для {@code ags.ra}.
 */
public class JdbcRaReportDao implements RaReportDao {

    private static final Logger log = Logger.getLogger(JdbcRaReportDao.class.getName());
    private static final String COLUMNS = "ra_key, ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period, "
            + "ra_arrived, ra_arrived_date, ra_returned, ra_returned_date, ra_sent, ra_sent_date, "
            + "ra_note_t, ra_created, ra_org_sender, ra_note";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcRaReportDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
        return schemaPrefix() + "ra";
    }

    @Override
    public Optional<RaReport> findById(int raKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + table() + " WHERE ra_key = ?";
        log.log(Level.FINE, "findById ra_key={0}", raKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить отчёт " + raKey, exception);
        }
    }

    @Override
    public RaReport create(RaReport report) {
        String sql = "INSERT INTO " + table() + " ("
                + "ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period, "
                + "ra_arrived, ra_arrived_date, ra_returned, ra_returned_date, ra_sent, ra_sent_date, "
                + "ra_note_t, ra_created, ra_org_sender, ra_note"
                + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME(), ?, ?)";
        log.log(Level.INFO, "Creating ra for cac={0}", report.raCac());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, report);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не получен ra_key после INSERT");
                }
                int raKey = keys.getInt(1);
                return findById(raKey).orElseThrow(() -> new DaoException("Отчёт " + raKey + " не найден после INSERT"));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать отчёт", exception);
        }
    }

    @Override
    public RaReport update(RaReport report) {
        Objects.requireNonNull(report.raKey(), "raKey");
        String sql = "UPDATE " + table() + " SET "
                + "ra_num = ?, ra_date = ?, ra_cac = ?, ra_type = ?, ra_work_type = ?, ra_period = ?, "
                + "ra_arrived = ?, ra_arrived_date = ?, ra_returned = ?, ra_returned_date = ?, "
                + "ra_sent = ?, ra_sent_date = ?, ra_note_t = ?, ra_org_sender = ?, ra_note = ? "
                + "WHERE ra_key = ?";
        log.log(Level.INFO, "Updating ra_key={0}", report.raKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, report);
            statement.setInt(16, report.raKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Отчёт " + report.raKey() + " не найден для обновления");
            }
            return findById(report.raKey()).orElseThrow();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить отчёт " + report.raKey(), exception);
        }
    }

    @Override
    public boolean deleteById(int raKey) {
        String sql = "DELETE FROM " + table() + " WHERE ra_key = ?";
        log.log(Level.INFO, "Deleting ra_key={0}", raKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить отчёт " + raKey, exception);
        }
    }

    @Override
    public boolean hasChanges(int raKey) {
        // Колонка FK в ags.ra_change: [raс_ra] (кириллическая «с»).
        String sql = "SELECT TOP 1 1 FROM " + schemaPrefix() + "ra_change WHERE [raс_ra] = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось проверить изменения отчёта " + raKey, exception);
        }
    }

    private void bindMutable(PreparedStatement statement, RaReport report) throws SQLException {
        statement.setString(1, report.raNum());
        setDate(statement, 2, report.raDate());
        statement.setInt(3, report.raCac());
        statement.setString(4, report.raType());
        setString(statement, 5, report.raWorkType());
        statement.setInt(6, report.raPeriod());
        setString(statement, 7, report.raArrived());
        setDate(statement, 8, report.raArrivedDate());
        setString(statement, 9, report.raReturned());
        setDate(statement, 10, report.raReturnedDate());
        setString(statement, 11, report.raSent());
        setDate(statement, 12, report.raSentDate());
        setString(statement, 13, report.raNoteT());
        statement.setInt(14, report.raOrgSender());
        setString(statement, 15, report.raNote());
    }

    private RaReport mapRow(ResultSet resultSet) throws SQLException {
        return new RaReport(
                resultSet.getInt("ra_key"),
                resultSet.getString("ra_num"),
                toLocalDate(resultSet.getDate("ra_date")),
                resultSet.getInt("ra_cac"),
                resultSet.getString("ra_type"),
                resultSet.getString("ra_work_type"),
                resultSet.getInt("ra_period"),
                resultSet.getString("ra_arrived"),
                toLocalDate(resultSet.getDate("ra_arrived_date")),
                resultSet.getString("ra_returned"),
                toLocalDate(resultSet.getDate("ra_returned_date")),
                resultSet.getString("ra_sent"),
                toLocalDate(resultSet.getDate("ra_sent_date")),
                resultSet.getString("ra_note_t"),
                toLocalDateTime(resultSet.getTimestamp("ra_created")),
                resultSet.getInt("ra_org_sender"),
                resultSet.getString("ra_note")
        );
    }

    private static void setString(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setString(index, value);
        }
    }

    private static void setDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DATE);
        } else {
            statement.setDate(index, Date.valueOf(value));
        }
    }

    private static LocalDate toLocalDate(Date date) {
        return date == null ? null : date.toLocalDate();
    }

    private static LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toLocalDateTime();
    }
}
