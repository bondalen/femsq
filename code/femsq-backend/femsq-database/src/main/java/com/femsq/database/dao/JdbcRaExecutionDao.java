package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaExecution;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaExecutionDao}.
 */
public class JdbcRaExecutionDao implements RaExecutionDao {

    private static final Logger log = Logger.getLogger(JdbcRaExecutionDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_execution";

    private final ConnectionFactory connectionFactory;

    public JdbcRaExecutionDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public RaExecution createRunning(int auditId, boolean addRa) {
        String sql = "INSERT INTO " + TABLE_NAME + " (exec_adt_key, exec_status, exec_add_ra, exec_started) "
                + "VALUES (?, N'RUNNING', ?, SYSUTCDATETIME())";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, auditId);
            statement.setBoolean(2, addRa);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить exec_key для запуска ревизии");
                }
                int execKey = keys.getInt(1);
                return new RaExecution(execKey, auditId, "RUNNING", addRa, null, null, null);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to create running execution", exception);
            throw new DaoException("Не удалось создать запись запуска ревизии", exception);
        }
    }

    @Override
    public void markCompleted(int execKey) {
        updateFinalState(execKey, "COMPLETED", null);
    }

    @Override
    public void markFailed(int execKey, String errorMessage) {
        updateFinalState(execKey, "FAILED", errorMessage);
    }

    @Override
    public Optional<RaExecution> findLatestByAuditId(int auditId) {
        String sql = "SELECT TOP 1 exec_key, exec_adt_key, exec_status, exec_add_ra, exec_started, exec_finished, exec_error "
                + "FROM " + TABLE_NAME + " WHERE exec_adt_key = ? ORDER BY exec_key DESC";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, auditId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(map(resultSet));
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to read execution state", exception);
            throw new DaoException("Не удалось получить статус выполнения ревизии " + auditId, exception);
        }
    }

    private void updateFinalState(int execKey, String status, String errorMessage) {
        String sql = "UPDATE " + TABLE_NAME + " SET exec_status = ?, exec_finished = SYSUTCDATETIME(), exec_error = ? "
                + "WHERE exec_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, status);
            statement.setNString(2, errorMessage);
            statement.setInt(3, execKey);
            statement.executeUpdate();
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to update execution final state", exception);
            throw new DaoException("Не удалось обновить статус выполнения ревизии", exception);
        }
    }

    private RaExecution map(ResultSet resultSet) throws SQLException {
        Timestamp started = resultSet.getTimestamp("exec_started");
        Timestamp finished = resultSet.getTimestamp("exec_finished");
        return new RaExecution(
                resultSet.getInt("exec_key"),
                resultSet.getInt("exec_adt_key"),
                resultSet.getNString("exec_status"),
                resultSet.getBoolean("exec_add_ra"),
                started != null ? started.toLocalDateTime() : null,
                finished != null ? finished.toLocalDateTime() : null,
                resultSet.getNString("exec_error")
        );
    }
}
