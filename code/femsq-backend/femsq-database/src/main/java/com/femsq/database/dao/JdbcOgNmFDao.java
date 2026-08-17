package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.OgNmF;
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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC {@link OgNmFDao}.
 */
public class JdbcOgNmFDao implements OgNmFDao {

    private static final Logger log = Logger.getLogger(JdbcOgNmFDao.class.getName());
    private static final String TABLE = "ogNmF";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    /**
     * @param connectionFactory фабрика
     * @param configurationService схема
     */
    public JdbcOgNmFDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String tableName() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.isBlank()) {
                return "ags." + TABLE;
            }
            return schema.trim() + "." + TABLE;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration missing for ogNmF, fallback ags_test", exception);
            return "ags_test." + TABLE;
        }
    }

    @Override
    public List<OgNmF> findByOrg(int ogKey) {
        String sql = "SELECT onfKey, onfOg, onfName, onfNameExt, onfStart, onfEnd FROM " + tableName()
                + " WHERE onfOg = ? ORDER BY onfKey";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ogKey);
            try (ResultSet rs = statement.executeQuery()) {
                List<OgNmF> rows = new ArrayList<>();
                while (rs.next()) {
                    rows.add(map(rs));
                }
                return List.copyOf(rows);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось прочитать ogNmF для onfOg=" + ogKey, exception);
        }
    }

    @Override
    public OgNmF create(OgNmF row) {
        Objects.requireNonNull(row, "row");
        if (row.onfKey() != null) {
            throw new IllegalArgumentException("Новый ogNmF не должен содержать onfKey");
        }
        String sql = "INSERT INTO " + tableName()
                + " (onfOg, onfName, onfNameExt, onfStart, onfEnd) VALUES (?, ?, ?, ?, ?)";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bind(statement, row);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не удалось получить onfKey");
                }
                return new OgNmF(
                        keys.getInt(1),
                        row.onfOg(),
                        row.onfName(),
                        row.onfNameExt(),
                        row.onfStart(),
                        row.onfEnd()
                );
            }
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать ogNmF для onfOg=" + row.onfOg(), exception);
        }
    }

    @Override
    public OgNmF update(OgNmF row) {
        Objects.requireNonNull(row, "row");
        if (row.onfKey() == null) {
            throw new IllegalArgumentException("Для обновления ogNmF нужен onfKey");
        }
        String sql = "UPDATE " + tableName()
                + " SET onfOg = ?, onfName = ?, onfNameExt = ?, onfStart = ?, onfEnd = ? WHERE onfKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, row);
            statement.setInt(6, row.onfKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("ogNmF не найден: onfKey=" + row.onfKey());
            }
            return row;
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить ogNmF onfKey=" + row.onfKey(), exception);
        }
    }

    @Override
    public boolean deleteById(int onfKey) {
        String sql = "DELETE FROM " + tableName() + " WHERE onfKey = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, onfKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить ogNmF onfKey=" + onfKey, exception);
        }
    }

    private static void bind(PreparedStatement statement, OgNmF row) throws SQLException {
        statement.setInt(1, row.onfOg());
        statement.setNString(2, row.onfName());
        statement.setNString(3, row.onfNameExt());
        setDate(statement, 4, row.onfStart());
        setDate(statement, 5, row.onfEnd());
    }

    private static void setDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DATE);
        } else {
            statement.setDate(index, Date.valueOf(value));
        }
    }

    private static OgNmF map(ResultSet rs) throws SQLException {
        Date start = rs.getDate("onfStart");
        Date end = rs.getDate("onfEnd");
        return new OgNmF(
                rs.getInt("onfKey"),
                rs.getInt("onfOg"),
                rs.getNString("onfName"),
                rs.getNString("onfNameExt"),
                start == null ? null : start.toLocalDate(),
                end == null ? null : end.toLocalDate()
        );
    }
}
