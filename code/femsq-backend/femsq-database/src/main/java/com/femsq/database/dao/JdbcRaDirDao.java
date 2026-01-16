package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaDir;
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
 * JDBC-реализация {@link RaDirDao} для работы с таблицей {@code ags.ra_dir}.
 */
public class JdbcRaDirDao implements RaDirDao {

    private static final Logger log = Logger.getLogger(JdbcRaDirDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_dir";

    private final ConnectionFactory connectionFactory;

    public JdbcRaDirDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaDir> findById(int key) {
        String sql = "SELECT [key], dir_name, dir, dir_created, dir_updated FROM " + TABLE_NAME + " WHERE [key] = ?";
        log.log(Level.FINE, "Executing findById for key={0}", key);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, key);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaDir(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить директорию с идентификатором " + key, exception);
        }
    }

    @Override
    public List<RaDir> findAll() {
        String sql = "SELECT [key], dir_name, dir, dir_created, dir_updated FROM " + TABLE_NAME + " ORDER BY [key]";
        log.fine("Executing findAll for ra_dir");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaDir> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaDir(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список директорий", exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_dir");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество директорий", exception);
        }
    }

    private RaDir mapRaDir(ResultSet resultSet) throws SQLException {
        return new RaDir(
                resultSet.getInt("key"),
                resultSet.getNString("dir_name"),
                resultSet.getNString("dir"),
                toLocalDateTime(resultSet.getTimestamp("dir_created")),
                toLocalDateTime(resultSet.getTimestamp("dir_updated"))
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }
}