package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaSumm;
import java.math.BigDecimal;
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
 * JDBC-реализация {@link RaSummDao} для {@code ags.ra_summ}.
 */
public class JdbcRaSummDao implements RaSummDao {

    private static final Logger log = Logger.getLogger(JdbcRaSummDao.class.getName());
    private static final String COLUMNS = "ras_key, ras_ra, ras_total, ras_work, ras_equip, ras_others, ras_date";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcRaSummDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
        return schemaPrefix() + "ra_summ";
    }

    @Override
    public Optional<RaSumm> findById(int rasKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + table() + " WHERE ras_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, rasKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить суммы " + rasKey, exception);
        }
    }

    @Override
    public List<RaSumm> findByRa(int raKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + table()
                + " WHERE ras_ra = ? ORDER BY ras_date DESC, ras_key DESC";
        log.log(Level.FINE, "findByRa ras_ra={0}", raKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaSumm> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось получить суммы отчёта " + raKey, exception);
        }
    }

    @Override
    public RaSumm create(RaSumm summ) {
        String sql = "INSERT INTO " + table()
                + " (ras_ra, ras_total, ras_work, ras_equip, ras_others, ras_date) VALUES (?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating ra_summ for ras_ra={0}", summ.rasRa());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, summ.rasRa());
            setMoney(statement, 2, summ.rasTotal());
            setMoney(statement, 3, summ.rasWork());
            setMoney(statement, 4, summ.rasEquip());
            setMoney(statement, 5, summ.rasOthers());
            LocalDateTime rasDate = summ.rasDate() != null ? summ.rasDate() : LocalDateTime.now();
            statement.setTimestamp(6, Timestamp.valueOf(rasDate));
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new DaoException("Не получен ras_key после INSERT");
                }
                return findById(keys.getInt(1)).orElseThrow();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось создать суммы отчёта", exception);
        }
    }

    @Override
    public RaSumm update(RaSumm summ) {
        Objects.requireNonNull(summ.rasKey(), "rasKey");
        String sql = "UPDATE " + table()
                + " SET ras_ra = ?, ras_total = ?, ras_work = ?, ras_equip = ?, ras_others = ?, ras_date = ? "
                + "WHERE ras_key = ?";
        log.log(Level.INFO, "Updating ras_key={0}", summ.rasKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, summ.rasRa());
            setMoney(statement, 2, summ.rasTotal());
            setMoney(statement, 3, summ.rasWork());
            setMoney(statement, 4, summ.rasEquip());
            setMoney(statement, 5, summ.rasOthers());
            LocalDateTime rasDate = summ.rasDate() != null ? summ.rasDate() : LocalDateTime.now();
            statement.setTimestamp(6, Timestamp.valueOf(rasDate));
            statement.setInt(7, summ.rasKey());
            if (statement.executeUpdate() == 0) {
                throw new DaoException("Суммы " + summ.rasKey() + " не найдены для обновления");
            }
            return findById(summ.rasKey()).orElseThrow();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось обновить суммы " + summ.rasKey(), exception);
        }
    }

    @Override
    public boolean deleteById(int rasKey) {
        String sql = "DELETE FROM " + table() + " WHERE ras_key = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, rasKey);
            return statement.executeUpdate() > 0;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить суммы " + rasKey, exception);
        }
    }

    @Override
    public int deleteByRa(int raKey) {
        String sql = "DELETE FROM " + table() + " WHERE ras_ra = ?";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raKey);
            return statement.executeUpdate();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            throw new DaoException("Не удалось удалить суммы отчёта " + raKey, exception);
        }
    }

    private RaSumm mapRow(ResultSet resultSet) throws SQLException {
        Timestamp rasDate = resultSet.getTimestamp("ras_date");
        return new RaSumm(
                resultSet.getInt("ras_key"),
                resultSet.getInt("ras_ra"),
                resultSet.getBigDecimal("ras_total"),
                resultSet.getBigDecimal("ras_work"),
                resultSet.getBigDecimal("ras_equip"),
                resultSet.getBigDecimal("ras_others"),
                rasDate == null ? null : rasDate.toLocalDateTime()
        );
    }

    private static void setMoney(PreparedStatement statement, int index, BigDecimal value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DECIMAL);
        } else {
            statement.setBigDecimal(index, value);
        }
    }
}
