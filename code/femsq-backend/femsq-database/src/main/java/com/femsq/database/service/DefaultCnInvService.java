package com.femsq.database.service;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnInv;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Минимальный доменный сервис создания связи {@code ags.cnInv}.
 */
public class DefaultCnInvService implements CnInvService {

    private static final Logger log = Logger.getLogger(DefaultCnInvService.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public DefaultCnInvService(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService
    ) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    @Override
    public CnInv create(int invKey, int cnKey) {
        requirePositive("invKey", invKey);
        requirePositive("cnKey", cnKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                requireExists(connection, "SELECT 1 FROM " + schema + "inv WHERE iKey = ?", "СФ inv не найден: ", invKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "cn WHERE cn_key = ?", "Договор cn не найден: ", cnKey);
                CnInv existing = findByPair(connection, schema, invKey, cnKey);
                if (existing != null) {
                    connection.commit();
                    return existing;
                }
                Timestamp now = Timestamp.valueOf(LocalDateTime.now());
                int ciKey;
                try (PreparedStatement statement = connection.prepareStatement(
                        "INSERT INTO " + schema + "cnInv (ciInv, ciCn, ciTimeOfEntry) VALUES (?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    statement.setInt(1, invKey);
                    statement.setInt(2, cnKey);
                    statement.setTimestamp(3, now);
                    statement.executeUpdate();
                    try (ResultSet rs = statement.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new DaoException("Не удалось получить ciKey после INSERT cnInv");
                        }
                        ciKey = rs.getInt(1);
                    }
                }
                CnInv created = findById(connection, schema, ciKey);
                connection.commit();
                log.log(Level.INFO, "CnInvService.create ciKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciKey, invKey, cnKey});
                return created;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать cnInv для inv=" + invKey + ", cn=" + cnKey, exception);
        }
    }

    @Override
    public CnInv update(int ciKey, int invKey, int cnKey) {
        requirePositive("ciKey", ciKey);
        requirePositive("invKey", invKey);
        requirePositive("cnKey", cnKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                CnInv current = findById(connection, schema, ciKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "inv WHERE iKey = ?", "СФ inv не найден: ", invKey);
                requireExists(connection, "SELECT 1 FROM " + schema + "cn WHERE cn_key = ?", "Договор cn не найден: ", cnKey);
                if (current.ciInv() == invKey && current.ciCn() == cnKey) {
                    connection.commit();
                    return current;
                }
                CnInv duplicate = findByPair(connection, schema, invKey, cnKey);
                if (duplicate != null && !Objects.equals(duplicate.ciKey(), ciKey)) {
                    throw new IllegalArgumentException(
                            "Связь cnInv уже существует: ciKey=" + duplicate.ciKey() + " (inv=" + invKey + ", cn=" + cnKey + ")");
                }
                try (PreparedStatement statement = connection.prepareStatement(
                        "UPDATE " + schema + "cnInv SET ciInv = ?, ciCn = ? WHERE ciKey = ?")) {
                    statement.setInt(1, invKey);
                    statement.setInt(2, cnKey);
                    statement.setInt(3, ciKey);
                    int affected = statement.executeUpdate();
                    if (affected == 0) {
                        throw new DaoException("Не удалось обновить cnInv ciKey=" + ciKey);
                    }
                }
                CnInv updated = findById(connection, schema, ciKey);
                connection.commit();
                log.log(Level.INFO, "CnInvService.update ciKey={0} invKey={1} cnKey={2}",
                        new Object[]{ciKey, invKey, cnKey});
                return updated;
            } catch (RuntimeException | SQLException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить cnInv ciKey=" + ciKey, exception);
        }
    }

    @Override
    public boolean delete(int ciKey) {
        requirePositive("ciKey", ciKey);
        String schema = schemaPrefix();
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "DELETE FROM " + schema + "cnInv WHERE ciKey = ?")) {
            statement.setInt(1, ciKey);
            boolean deleted = statement.executeUpdate() > 0;
            log.log(Level.INFO, "CnInvService.delete ciKey={0} deleted={1}", new Object[]{ciKey, deleted});
            return deleted;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить cnInv ciKey=" + ciKey, exception);
        }
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                return "ags.";
            }
            return schema.trim() + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration missing for cnInv, fallback ags.", exception);
            return "ags.";
        }
    }

    private static void requireExists(Connection connection, String sql, String message, int key) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, key);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(message + key);
                }
            }
        }
    }

    private static void requirePositive(String label, int key) {
        if (key <= 0) {
            throw new IllegalArgumentException(label + " должен быть положительным: " + key);
        }
    }

    private static CnInv findByPair(Connection connection, String schema, int invKey, int cnKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ciKey, ciInv, ciCn, ciTimeOfEntry FROM " + schema + "cnInv WHERE ciInv = ? AND ciCn = ?")) {
            statement.setInt(1, invKey);
            statement.setInt(2, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    private static CnInv findById(Connection connection, String schema, int ciKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT ciKey, ciInv, ciCn, ciTimeOfEntry FROM " + schema + "cnInv WHERE ciKey = ?")) {
            statement.setInt(1, ciKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new DaoException("Не удалось перечитать cnInv ciKey=" + ciKey);
                }
                return mapRow(rs);
            }
        }
    }

    private static CnInv mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("ciTimeOfEntry");
        OffsetDateTime entered = ts == null
                ? null
                : ts.toLocalDateTime().atZone(ZoneId.systemDefault()).toOffsetDateTime();
        return new CnInv(
                rs.getInt("ciKey"),
                rs.getInt("ciInv"),
                rs.getInt("ciCn"),
                entered
        );
    }
}
