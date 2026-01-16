package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaAt;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaAtDao} для работы с таблицей {@code ags.ra_at}.
 */
public class JdbcRaAtDao implements RaAtDao {

    private static final Logger log = Logger.getLogger(JdbcRaAtDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_at";

    private final ConnectionFactory connectionFactory;

    public JdbcRaAtDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaAt> findById(int atKey) {
        String sql = "SELECT at_key, at_name, at_created, at_updated FROM " + TABLE_NAME + " WHERE at_key = ?";
        log.log(Level.FINE, "Executing findById for atKey={0}", atKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, atKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaAt(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить тип ревизии с идентификатором " + atKey, exception);
        }
    }

    @Override
    public List<RaAt> findAll() {
        String sql = "SELECT at_key, at_name, at_created, at_updated FROM " + TABLE_NAME + " ORDER BY at_key";
        log.fine("Executing findAll for ra_at");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaAt> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaAt(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список типов ревизий", exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_at");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество типов ревизий", exception);
        }
    }

    private RaAt mapRaAt(ResultSet resultSet) throws SQLException {
        return new RaAt(
                resultSet.getInt("at_key"),
                resultSet.getNString("at_name"),
                toLocalDateTime(resultSet.getTimestamp("at_created")),
                toLocalDateTime(resultSet.getTimestamp("at_updated"))
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }
}