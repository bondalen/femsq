package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoadMonf;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC {@link ImpIpgLoadMonfDao} (C2 §6.4).
 */
public class JdbcImpIpgLoadMonfDao implements ImpIpgLoadMonfDao {

    private static final Logger log = Logger.getLogger(JdbcImpIpgLoadMonfDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcImpIpgLoadMonfDao(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schema() {
        try {
            String value = configurationService.loadConfig().schema();
            if (value == null || value.isBlank()) {
                return "ags";
            }
            return value.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Schema missing, default ags", exception);
            return "ags";
        }
    }

    private String q(String table) {
        return schema() + "." + table;
    }

    private String selectCols() {
        return "SELECT iilmKey, iilmLoad, iilmUtPl, iilmNm, iilmFilePath, iilmSheet,"
                + " iilmLimColumn, iilmQuarter, iilmSumFirst, iilmNote, iilmCreated, iilmResults"
                + " FROM " + q("impIpgLoadMonf");
    }

    @Override
    public List<ImpIpgLoadMonf> findByLoad(int loadKey) {
        String sql = selectCols() + " WHERE iilmLoad = ? ORDER BY iilmKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, loadKey);
            return mapAll(statement);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpgLoadMonf по load=" + loadKey, exception);
        }
    }

    @Override
    public List<ImpIpgLoadMonf> findByIpg(int ipgKey) {
        String sql = "SELECT m.iilmKey, m.iilmLoad, m.iilmUtPl, m.iilmNm, m.iilmFilePath, m.iilmSheet,"
                + " m.iilmLimColumn, m.iilmQuarter, m.iilmSumFirst, m.iilmNote, m.iilmCreated, m.iilmResults"
                + " FROM " + q("impIpgLoadMonf") + " m"
                + " INNER JOIN " + q("impIpgLoad") + " l ON l.iilKey = m.iilmLoad"
                + " WHERE l.iilIpg = ? ORDER BY m.iilmKey DESC";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ipgKey);
            return mapAll(statement);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpgLoadMonf по ipg=" + ipgKey, exception);
        }
    }

    @Override
    public Optional<ImpIpgLoadMonf> findByKey(int iilmKey) {
        String sql = selectCols() + " WHERE iilmKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iilmKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapRow(resultSet));
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать impIpgLoadMonf=" + iilmKey, exception);
        }
    }

    @Override
    public ImpIpgLoadMonf insert(
            int loadKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note) {
        String sql = "INSERT INTO " + q("impIpgLoadMonf")
                + " (iilmLoad, iilmUtPl, iilmNm, iilmFilePath, iilmSheet, iilmLimColumn,"
                + " iilmQuarter, iilmSumFirst, iilmNote)"
                + " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, loadKey);
            setNullableInt(statement, 2, utPlKey);
            statement.setString(3, name);
            setNullableString(statement, 4, filePath);
            setNullableString(statement, 5, sheet);
            setNullableString(statement, 6, limColumn);
            statement.setBoolean(7, quarter);
            setNullableInt(statement, 8, sumFirst);
            setNullableString(statement, 9, note);
            statement.executeUpdate();
            int key = readGeneratedKey(statement);
            log.info(() -> "insertMonf iilmKey=" + key + " load=" + loadKey);
            return findByKey(key).orElseThrow(() -> new DaoException("impIpgLoadMonf не найден после insert: " + key));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать impIpgLoadMonf load=" + loadKey, exception);
        }
    }

    @Override
    public ImpIpgLoadMonf update(
            int iilmKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            boolean quarter,
            Integer sumFirst,
            String note) {
        String sql = "UPDATE " + q("impIpgLoadMonf")
                + " SET iilmUtPl = ?, iilmNm = ?, iilmFilePath = ?, iilmSheet = ?, iilmLimColumn = ?,"
                + " iilmQuarter = ?, iilmSumFirst = ?, iilmNote = ?"
                + " WHERE iilmKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            setNullableInt(statement, 1, utPlKey);
            statement.setString(2, name);
            setNullableString(statement, 3, filePath);
            setNullableString(statement, 4, sheet);
            setNullableString(statement, 5, limColumn);
            statement.setBoolean(6, quarter);
            setNullableInt(statement, 7, sumFirst);
            setNullableString(statement, 8, note);
            statement.setInt(9, iilmKey);
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("impIpgLoadMonf не найден: " + iilmKey);
            }
            return findByKey(iilmKey)
                    .orElseThrow(() -> new DaoException("impIpgLoadMonf пропал после update: " + iilmKey));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить impIpgLoadMonf=" + iilmKey, exception);
        }
    }

    @Override
    public boolean delete(int iilmKey) {
        String sql = "DELETE FROM " + q("impIpgLoadMonf") + " WHERE iilmKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, iilmKey);
            int deleted = statement.executeUpdate();
            log.info(() -> "deleteMonf iilmKey=" + iilmKey + " deleted=" + deleted);
            return deleted > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить impIpgLoadMonf=" + iilmKey, exception);
        }
    }

    @Override
    public void updateResults(int iilmKey, String html) {
        String sql = "UPDATE " + q("impIpgLoadMonf") + " SET iilmResults = ? WHERE iilmKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            setNullableString(statement, 1, html);
            statement.setInt(2, iilmKey);
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("impIpgLoadMonf не найден: " + iilmKey);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось сохранить iilmResults для Monf=" + iilmKey, exception);
        }
    }

    private List<ImpIpgLoadMonf> mapAll(PreparedStatement statement) throws SQLException {
        try (ResultSet resultSet = statement.executeQuery()) {
            List<ImpIpgLoadMonf> rows = new ArrayList<>();
            while (resultSet.next()) {
                rows.add(mapRow(resultSet));
            }
            return List.copyOf(rows);
        }
    }

    private static ImpIpgLoadMonf mapRow(ResultSet resultSet) throws SQLException {
        int utPl = resultSet.getInt("iilmUtPl");
        Integer utPlKey = resultSet.wasNull() ? null : utPl;
        int sumFirst = resultSet.getInt("iilmSumFirst");
        Integer sumFirstVal = resultSet.wasNull() ? null : sumFirst;
        Timestamp created = resultSet.getTimestamp("iilmCreated");
        LocalDateTime createdAt = created != null ? created.toLocalDateTime() : null;
        return new ImpIpgLoadMonf(
                resultSet.getInt("iilmKey"),
                resultSet.getInt("iilmLoad"),
                utPlKey,
                resultSet.getString("iilmNm"),
                resultSet.getString("iilmFilePath"),
                resultSet.getString("iilmSheet"),
                resultSet.getString("iilmLimColumn"),
                resultSet.getBoolean("iilmQuarter"),
                sumFirstVal,
                resultSet.getString("iilmNote"),
                createdAt,
                resultSet.getString("iilmResults"));
    }

    private static int readGeneratedKey(PreparedStatement statement) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (!keys.next()) {
                throw new DaoException("IDENTITY key не получен");
            }
            return keys.getInt(1);
        }
    }

    private static void setNullableString(PreparedStatement statement, int index, String value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setString(index, value);
        }
    }

    private static void setNullableInt(PreparedStatement statement, int index, Integer value)
            throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.INTEGER);
        } else {
            statement.setInt(index, value);
        }
    }
}
