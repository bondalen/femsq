package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtSn;
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
 * JDBC-реализация {@link RaFtSnDao} для работы с таблицей {@code ags.ra_ft_sn}.
 */
public class JdbcRaFtSnDao implements RaFtSnDao {

    private static final Logger log = Logger.getLogger(JdbcRaFtSnDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_ft_sn";

    private final ConnectionFactory connectionFactory;

    public JdbcRaFtSnDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaFtSn> findById(int ftsnKey) {
        String sql = "SELECT ftsn_key, ftsn_ft_s, ftsn_name, ftsn_created, ftsn_updated " +
                "FROM " + TABLE_NAME + " WHERE ftsn_key = ?";
        log.log(Level.FINE, "Executing findById for ftsnKey={0}", ftsnKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftsnKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaFtSn(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить имя источника с идентификатором " + ftsnKey, exception);
        }
    }

    @Override
    public List<RaFtSn> findAll() {
        String sql = "SELECT ftsn_key, ftsn_ft_s, ftsn_name, ftsn_created, ftsn_updated " +
                "FROM " + TABLE_NAME + " ORDER BY ftsn_key";
        log.fine("Executing findAll for ra_ft_sn");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaFtSn> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaFtSn(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список имен источников", exception);
        }
    }

    @Override
    public List<RaFtSn> findByFtS(int ftSKey) {
        String sql = "SELECT ftsn_key, ftsn_ft_s, ftsn_name, ftsn_created, ftsn_updated " +
                "FROM " + TABLE_NAME + " WHERE ftsn_ft_s = ? ORDER BY ftsn_key";
        log.log(Level.FINE, "Executing findByFtS for ftSKey={0}", ftSKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftSKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaFtSn> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRaFtSn(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByFtS", exception);
            throw new DaoException("Не удалось получить имена для источника " + ftSKey, exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_ft_sn");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество имен источников", exception);
        }
    }

    @Override
    public RaFtSn create(RaFtSn raFtSn) {
        Objects.requireNonNull(raFtSn, "raFtSn");
        String sql = "INSERT INTO " + TABLE_NAME + " (ftsn_ft_s, ftsn_name) VALUES (?, ?)";
        log.log(Level.INFO, "Creating file source name {0} for source {1}", new Object[]{raFtSn.ftsnName(), raFtSn.ftsnFtS()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, raFtSn.ftsnFtS());
            statement.setNString(2, raFtSn.ftsnName());
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int generatedId = generatedKeys.getInt(1);
                    return raFtSnWithId(raFtSn, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданного имени источника");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать имя источника", exception);
        }
    }

    @Override
    public RaFtSn update(RaFtSn raFtSn) {
        Objects.requireNonNull(raFtSn, "raFtSn");
        if (raFtSn.ftsnKey() == null) {
            throw new DaoException("Для обновления имени источника необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME
                + " SET ftsn_ft_s = ?, ftsn_name = ?, ftsn_updated = GETDATE() WHERE ftsn_key = ?";
        log.log(Level.INFO, "Updating file source name {0}", raFtSn.ftsnKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raFtSn.ftsnFtS());
            statement.setNString(2, raFtSn.ftsnName());
            statement.setInt(3, raFtSn.ftsnKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Имя источника с идентификатором " + raFtSn.ftsnKey() + " не найдено");
            }
            return raFtSn;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить имя источника", exception);
        }
    }

    @Override
    public boolean deleteById(int ftsnKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE ftsn_key = ?";
        log.log(Level.INFO, "Deleting file source name {0}", ftsnKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftsnKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить имя источника " + ftsnKey, exception);
        }
    }

    private RaFtSn mapRaFtSn(ResultSet resultSet) throws SQLException {
        return new RaFtSn(
                resultSet.getInt("ftsn_key"),
                resultSet.getInt("ftsn_ft_s"),
                resultSet.getNString("ftsn_name"),
                toLocalDateTime(resultSet.getTimestamp("ftsn_created")),
                toLocalDateTime(resultSet.getTimestamp("ftsn_updated"))
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private RaFtSn raFtSnWithId(RaFtSn raFtSn, int generatedId) {
        return new RaFtSn(
                generatedId,
                raFtSn.ftsnFtS(),
                raFtSn.ftsnName(),
                raFtSn.ftsnCreated(),
                raFtSn.ftsnUpdated()
        );
    }
}
