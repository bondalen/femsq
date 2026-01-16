package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFt;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaFtDao} для работы со справочником типов файлов.
 */
public class JdbcRaFtDao implements RaFtDao {

    private static final Logger log = Logger.getLogger(JdbcRaFtDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_ft";

    private final ConnectionFactory connectionFactory;

    public JdbcRaFtDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaFt> findById(int ftKey) {
        String sql = "SELECT ft_key, ft_name FROM " + TABLE_NAME + " WHERE ft_key = ?";
        log.log(Level.FINE, "Executing findById for ftKey={0}", ftKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaFt(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить тип файла с идентификатором " + ftKey, exception);
        }
    }

    @Override
    public List<RaFt> findAll() {
        String sql = "SELECT ft_key, ft_name FROM " + TABLE_NAME + " ORDER BY ft_key";
        log.fine("Executing findAll for ra_ft");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaFt> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaFt(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список типов файлов", exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_ft");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество типов файлов", exception);
        }
    }

    private RaFt mapRaFt(ResultSet resultSet) throws SQLException {
        return new RaFt(
                resultSet.getInt("ft_key"),
                resultSet.getNString("ft_name")
        );
    }
}
