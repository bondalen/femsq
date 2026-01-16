package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSt;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link RaFtStDao} для работы с таблицей {@code ags.ra_ft_st}.
 */
public class JdbcRaFtStDao implements RaFtStDao {

    private static final Logger log = Logger.getLogger(JdbcRaFtStDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_ft_st";

    private final ConnectionFactory connectionFactory;

    public JdbcRaFtStDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaFtSt> findById(int stKey) {
        String sql = "SELECT st_key, st_name, st_created, st_updated FROM " + TABLE_NAME + " WHERE st_key = ?";
        log.log(Level.FINE, "Executing findById for stKey={0}", stKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaFtSt(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить тип источника с идентификатором " + stKey, exception);
        }
    }

    @Override
    public List<RaFtSt> findAll() {
        String sql = "SELECT st_key, st_name, st_created, st_updated FROM " + TABLE_NAME + " ORDER BY st_key";
        log.fine("Executing findAll for ra_ft_st");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaFtSt> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaFtSt(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список типов источников", exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_ft_st");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество типов источников", exception);
        }
    }

    @Override
    public RaFtSt create(RaFtSt raFtSt) {
        Objects.requireNonNull(raFtSt, "raFtSt");
        String sql = "INSERT INTO " + TABLE_NAME + " (st_name) VALUES (?)";
        log.log(Level.INFO, "Creating file source type {0}", raFtSt.stName());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setNString(1, raFtSt.stName());
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int generatedId = generatedKeys.getInt(1);
                    return raFtStWithId(raFtSt, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданного типа источника");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать тип источника", exception);
        }
    }

    @Override
    public RaFtSt update(RaFtSt raFtSt) {
        Objects.requireNonNull(raFtSt, "raFtSt");
        if (raFtSt.stKey() == null) {
            throw new DaoException("Для обновления типа источника необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME + " SET st_name = ?, st_updated = GETDATE() WHERE st_key = ?";
        log.log(Level.INFO, "Updating file source type {0}", raFtSt.stKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setNString(1, raFtSt.stName());
            statement.setInt(2, raFtSt.stKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Тип источника с идентификатором " + raFtSt.stKey() + " не найден");
            }
            return raFtSt;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить тип источника", exception);
        }
    }

    @Override
    public boolean deleteById(int stKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE st_key = ?";
        log.log(Level.INFO, "Deleting file source type {0}", stKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, stKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить тип источника " + stKey, exception);
        }
    }

    private RaFtSt mapRaFtSt(ResultSet resultSet) throws SQLException {
        return new RaFtSt(
                resultSet.getInt("st_key"),
                resultSet.getNString("st_name"),
                toLocalDateTime(resultSet.getTimestamp("st_created")),
                toLocalDateTime(resultSet.getTimestamp("st_updated"))
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private RaFtSt raFtStWithId(RaFtSt raFtSt, int generatedId) {
        return new RaFtSt(
                generatedId,
                raFtSt.stName(),
                raFtSt.stCreated(),
                raFtSt.stUpdated()
        );
    }
}
