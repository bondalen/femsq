package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaA;
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
 * JDBC-реализация {@link RaADao} для работы с таблицей {@code ags.ra_a}.
 */
public class JdbcRaADao implements RaADao {

    private static final Logger log = Logger.getLogger(JdbcRaADao.class.getName());
    private static final String TABLE_NAME = "ags.ra_a";

    private final ConnectionFactory connectionFactory;

    public JdbcRaADao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaA> findById(long adtKey) {
        String sql = "SELECT adt_key, adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA, adt_created, adt_updated "
                + "FROM " + TABLE_NAME + " WHERE adt_key = ?";
        log.log(Level.FINE, "Executing findById for adtKey={0}", adtKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, adtKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaA(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить ревизию с идентификатором " + adtKey, exception);
        }
    }

    @Override
    public List<RaA> findAll() {
        String sql = "SELECT adt_key, adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA, adt_created, adt_updated "
                + "FROM " + TABLE_NAME + " ORDER BY adt_key";
        log.fine("Executing findAll for ra_a");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaA> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaA(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список ревизий", exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_a");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество ревизий", exception);
        }
    }

    @Override
    public RaA create(RaA raA) {
        Objects.requireNonNull(raA, "raA");
        String sql = "INSERT INTO " + TABLE_NAME
                + " (adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating audit {0}", raA.adtName());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindRaA(statement, raA);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    long generatedId = generatedKeys.getLong(1);
                    return raAWithId(raA, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданной ревизии");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать ревизию", exception);
        }
    }

    @Override
    public RaA update(RaA raA) {
        Objects.requireNonNull(raA, "raA");
        if (raA.adtKey() == null) {
            throw new DaoException("Для обновления ревизии необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME
                + " SET adt_name = ?, adt_date = ?, adt_results = ?, adt_dir = ?, adt_type = ?, adt_AddRA = ?, adt_updated = GETDATE() "
                + "WHERE adt_key = ?";
        log.log(Level.INFO, "Updating audit {0}", raA.adtKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindRaA(statement, raA);
            statement.setLong(7, raA.adtKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Ревизия с идентификатором " + raA.adtKey() + " не найдена");
            }
            return raA;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить ревизию", exception);
        }
    }

    @Override
    public boolean deleteById(long adtKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE adt_key = ?";
        log.log(Level.INFO, "Deleting audit {0}", adtKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, adtKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить ревизию " + adtKey, exception);
        }
    }

    private void bindRaA(PreparedStatement statement, RaA raA) throws SQLException {
        statement.setNString(1, raA.adtName());
        setTimestamp(statement, 2, raA.adtDate());
        setNStringNullable(statement, 3, raA.adtResults());
        statement.setInt(4, raA.adtDir());
        statement.setInt(5, raA.adtType());
        statement.setBoolean(6, raA.adtAddRA());
    }

    private void setTimestamp(PreparedStatement statement, int index, LocalDateTime dateTime) throws SQLException {
        if (dateTime == null) {
            statement.setNull(index, Types.TIMESTAMP);
        } else {
            statement.setTimestamp(index, Timestamp.valueOf(dateTime));
        }
    }

    private void setNStringNullable(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setNString(index, value);
        }
    }

    private RaA mapRaA(ResultSet resultSet) throws SQLException {
        return new RaA(
                resultSet.getLong("adt_key"),
                resultSet.getNString("adt_name"),
                toLocalDateTime(resultSet.getTimestamp("adt_date")),
                resultSet.getNString("adt_results"),
                resultSet.getInt("adt_dir"),
                resultSet.getInt("adt_type"),
                resultSet.getBoolean("adt_AddRA"),
                toLocalDateTime(resultSet.getTimestamp("adt_created")),
                toLocalDateTime(resultSet.getTimestamp("adt_updated"))
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private RaA raAWithId(RaA raA, long generatedId) {
        return new RaA(
                generatedId,
                raA.adtName(),
                raA.adtDate(),
                raA.adtResults(),
                raA.adtDir(),
                raA.adtType(),
                raA.adtAddRA(),
                raA.adtCreated(),
                raA.adtUpdated()
        );
    }
}