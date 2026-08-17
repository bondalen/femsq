package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Cn;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CnDao}.
 */
public class JdbcCnDao implements CnDao {

    private static final Logger log = Logger.getLogger(JdbcCnDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String tableName() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                return "ags.cn";
            }
            return schema.trim() + ".cn";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using ags.cn", exception);
            return "ags.cn";
        }
    }

    @Override
    public Optional<Cn> findById(int cnKey) {
        String sql = "SELECT cn_key, cn_number, cn_date, cn_note, cnMark FROM " + tableName() + " WHERE cn_key = ?";
        log.log(Level.FINE, "Executing Cn.findById cnKey={0}", cnKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cnKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to find cn", exception);
            throw new DaoException("Не удалось получить договор cn_key=" + cnKey, exception);
        }
    }

    @Override
    public Cn update(Cn cn) {
        Objects.requireNonNull(cn, "cn");
        if (cn.cnKey() == null || cn.cnKey() <= 0) {
            throw new DaoException("Для обновления cn нужен cn_key");
        }
        String sql = "UPDATE " + tableName() + " SET cn_date = ?, cn_note = ?, cnMark = ? WHERE cn_key = ?";
        log.log(Level.INFO, "Updating cn {0}", cn.cnKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (cn.cnDate() == null) {
                statement.setNull(1, Types.DATE);
            } else {
                statement.setDate(1, java.sql.Date.valueOf(cn.cnDate()));
            }
            if (cn.cnNote() == null || cn.cnNote().isBlank()) {
                statement.setNull(2, Types.NVARCHAR);
            } else {
                statement.setNString(2, cn.cnNote().trim());
            }
            if (cn.cnMark() == null) {
                statement.setNull(3, Types.INTEGER);
            } else {
                statement.setInt(3, cn.cnMark());
            }
            statement.setInt(4, cn.cnKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("cn_key=" + cn.cnKey() + " не найден");
            }
            return findById(cn.cnKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённый cn"));
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить cn_key=" + cn.cnKey(), exception);
        }
    }

    private static Cn mapRow(ResultSet rs) throws SQLException {
        java.sql.Date sqlDate = rs.getDate("cn_date");
        LocalDate cnDate = sqlDate != null ? sqlDate.toLocalDate() : null;
        return new Cn(
                rs.getInt("cn_key"),
                rs.getString("cn_number"),
                cnDate,
                rs.getString("cn_note"),
                (Integer) rs.getObject("cnMark")
        );
    }
}
