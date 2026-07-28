package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RalpRaAu;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RalpRaAuDao} для {@code ags.ralpRaAu}.
 */
public class JdbcRalpRaAuDao implements RalpRaAuDao {

    private static final Logger log = Logger.getLogger(JdbcRalpRaAuDao.class.getName());
    private static final String COLUMNS = "ralpraKey, ralpraRa, ralpraCostAndVat, ralpraArrived, ralpraArrivedDate, "
            + "ralpraReturned, ralpraReturnedDate, ralpraSent, ralpraSentDate, ralpraNote, ralpraStatus";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcRalpRaAuDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
        return schemaPrefix() + "ralpRaAu";
    }

    @Override
    public Optional<RalpRaAu> findById(int ralpraKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + table() + " WHERE ralpraKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralpraKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить строку Au " + ralpraKey, exception);
        }
    }

    @Override
    public List<RalpRaAu> findByRa(int ralprKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + table()
                + " WHERE ralpraRa = ? ORDER BY ralpraKey";
        log.log(Level.FINE, "findByRa ralpraRa={0}", ralprKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralprKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RalpRaAu> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить строки Au отчёта " + ralprKey, exception);
        }
    }

    @Override
    public RalpRaAu create(RalpRaAu row) {
        String sql = "INSERT INTO " + table()
                + " (ralpraRa, ralpraCostAndVat, ralpraArrived, ralpraArrivedDate, "
                + "ralpraReturned, ralpraReturnedDate, ralpraSent, ralpraSentDate, ralpraNote, ralpraStatus) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating ralpRaAu for ralpraRa={0}", row.ralpraRa());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, row);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не получен ralpraKey после INSERT");
                }
                return findById(keys.getInt(1)).orElseThrow();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать строку Au", exception);
        }
    }

    @Override
    public RalpRaAu update(RalpRaAu row) {
        Objects.requireNonNull(row.ralpraKey(), "ralpraKey");
        String sql = "UPDATE " + table()
                + " SET ralpraRa = ?, ralpraCostAndVat = ?, ralpraArrived = ?, ralpraArrivedDate = ?, "
                + "ralpraReturned = ?, ralpraReturnedDate = ?, ralpraSent = ?, ralpraSentDate = ?, "
                + "ralpraNote = ?, ralpraStatus = ? "
                + "WHERE ralpraKey = ?";
        log.log(Level.INFO, "Updating ralpRaAu ralpraKey={0}", row.ralpraKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, row);
            statement.setInt(11, row.ralpraKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("Строка Au " + row.ralpraKey() + " не найдена для обновления");
            }
            return findById(row.ralpraKey()).orElseThrow();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить строку Au " + row.ralpraKey(), exception);
        }
    }

    @Override
    public boolean deleteById(int ralpraKey) {
        String sql = "DELETE FROM " + table() + " WHERE ralpraKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ralpraKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить строку Au " + ralpraKey, exception);
        }
    }

    private void bindMutable(PreparedStatement statement, RalpRaAu row) throws SQLException {
        statement.setInt(1, row.ralpraRa());
        setMoney(statement, 2, row.ralpraCostAndVat());
        setNString(statement, 3, row.ralpraArrived());
        setDate(statement, 4, row.ralpraArrivedDate());
        setNString(statement, 5, row.ralpraReturned());
        setDate(statement, 6, row.ralpraReturnedDate());
        setNString(statement, 7, row.ralpraSent());
        setDate(statement, 8, row.ralpraSentDate());
        setNString(statement, 9, row.ralpraNote());
        statement.setInt(10, row.ralpraStatus());
    }

    private RalpRaAu mapRow(ResultSet resultSet) throws SQLException {
        return new RalpRaAu(
                resultSet.getInt("ralpraKey"),
                resultSet.getInt("ralpraRa"),
                resultSet.getBigDecimal("ralpraCostAndVat"),
                resultSet.getNString("ralpraArrived"),
                toLocalDate(resultSet.getDate("ralpraArrivedDate")),
                resultSet.getNString("ralpraReturned"),
                toLocalDate(resultSet.getDate("ralpraReturnedDate")),
                resultSet.getNString("ralpraSent"),
                toLocalDate(resultSet.getDate("ralpraSentDate")),
                resultSet.getNString("ralpraNote"),
                resultSet.getInt("ralpraStatus")
        );
    }

    private static void setMoney(PreparedStatement statement, int index, BigDecimal value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DECIMAL);
        } else {
            statement.setBigDecimal(index, value);
        }
    }

    private static void setNString(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setNString(index, value);
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
}
