package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaF;
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
 * JDBC-реализация {@link RaFDao} для работы с таблицей {@code ags.ra_f}.
 */
public class JdbcRaFDao implements RaFDao {

    private static final Logger log = Logger.getLogger(JdbcRaFDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_f";

    private final ConnectionFactory connectionFactory;

    public JdbcRaFDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaF> findById(long afKey) {
        String sql = "SELECT af_key, af_name, af_dir, af_type, af_execute, af_source, " +
                "af_created, af_updated, ra_org_sender, af_num " +
                "FROM " + TABLE_NAME + " WHERE af_key = ?";
        log.log(Level.FINE, "Executing findById for afKey={0}", afKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, afKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaF(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить файл с идентификатором " + afKey, exception);
        }
    }

    @Override
    public List<RaF> findAll() {
        String sql = "SELECT af_key, af_name, af_dir, af_type, af_execute, af_source, " +
                "af_created, af_updated, ra_org_sender, af_num " +
                "FROM " + TABLE_NAME + " ORDER BY af_dir, af_num, af_key";
        log.fine("Executing findAll for ra_f");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaF> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaF(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список файлов", exception);
        }
    }

    @Override
    public List<RaF> findByAuditId(long adtKey) {
        // Примечание: в оригинальной схеме Access нет прямой связи файла с ревизией
        // Файлы связаны с директорией, а директория с ревизией через форму
        // Этот метод оставлен для совместимости, но может требовать JOIN через ra_dir
        log.log(Level.WARNING, "findByAuditId called but af_adt_key field removed. Returning empty list.");
        return List.of();
    }

    @Override
    public List<RaF> findByDirId(int dirKey) {
        String sql = "SELECT af_key, af_name, af_dir, af_type, af_execute, af_source, " +
                "af_created, af_updated, ra_org_sender, af_num " +
                "FROM " + TABLE_NAME + " WHERE af_dir = ? ORDER BY af_num, af_key";
        log.log(Level.FINE, "Executing findByDirId for dirKey={0}", dirKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, dirKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaF> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRaF(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByDirId", exception);
            throw new DaoException("Не удалось получить файлы для директории " + dirKey, exception);
        }
    }

    @Override
    public List<RaF> findByFileType(int fileType) {
        String sql = "SELECT af_key, af_name, af_dir, af_type, af_execute, af_source, " +
                "af_created, af_updated, ra_org_sender, af_num " +
                "FROM " + TABLE_NAME + " WHERE af_type = ? ORDER BY af_dir, af_num, af_key";
        log.log(Level.FINE, "Executing findByFileType for fileType={0}", fileType);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileType);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaF> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRaF(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByFileType", exception);
            throw new DaoException("Не удалось получить файлы типа " + fileType, exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_f");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество файлов", exception);
        }
    }

    @Override
    public RaF create(RaF raF) {
        Objects.requireNonNull(raF, "raF");
        String sql = "INSERT INTO " + TABLE_NAME
                + " (af_name, af_dir, af_type, af_execute, af_source, ra_org_sender, af_num) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        log.log(Level.INFO, "Creating file {0}", raF.afName());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindRaF(statement, raF);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    long generatedId = generatedKeys.getLong(1);
                    return raFWithId(raF, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданного файла");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать файл", exception);
        }
    }

    @Override
    public RaF update(RaF raF) {
        Objects.requireNonNull(raF, "raF");
        if (raF.afKey() == null) {
            throw new DaoException("Для обновления файла необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME
                + " SET af_name = ?, af_dir = ?, af_type = ?, af_execute = ?, af_source = ?, " +
                "ra_org_sender = ?, af_num = ?, af_updated = GETDATE() "
                + "WHERE af_key = ?";
        log.log(Level.INFO, "Updating file {0}", raF.afKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindRaF(statement, raF);
            statement.setLong(8, raF.afKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Файл с идентификатором " + raF.afKey() + " не найден");
            }
            return raF;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить файл", exception);
        }
    }

    @Override
    public boolean deleteById(long afKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE af_key = ?";
        log.log(Level.INFO, "Deleting file {0}", afKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, afKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить файл " + afKey, exception);
        }
    }

    private void bindRaF(PreparedStatement statement, RaF raF) throws SQLException {
        statement.setNString(1, raF.afName());
        statement.setInt(2, raF.afDir());
        statement.setInt(3, raF.afType());
        statement.setBoolean(4, raF.afExecute());
        setBooleanNullable(statement, 5, raF.afSource());
        setIntNullable(statement, 6, raF.raOrgSender());
        setIntNullable(statement, 7, raF.afNum());
    }

    private void setIntNullable(PreparedStatement statement, int index, Integer value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.INTEGER);
        } else {
            statement.setInt(index, value);
        }
    }

    private void setBooleanNullable(PreparedStatement statement, int index, Boolean value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.BIT);
        } else {
            statement.setBoolean(index, value);
        }
    }

    private RaF mapRaF(ResultSet resultSet) throws SQLException {
        return new RaF(
                resultSet.getLong("af_key"),
                resultSet.getNString("af_name"),
                resultSet.getInt("af_dir"),
                resultSet.getInt("af_type"),
                resultSet.getBoolean("af_execute"),
                getBooleanNullable(resultSet, "af_source"),
                toLocalDateTime(resultSet.getTimestamp("af_created")),
                toLocalDateTime(resultSet.getTimestamp("af_updated")),
                getIntNullable(resultSet, "ra_org_sender"),
                getIntNullable(resultSet, "af_num")
        );
    }

    private Integer getIntNullable(ResultSet resultSet, String columnName) throws SQLException {
        int value = resultSet.getInt(columnName);
        return resultSet.wasNull() ? null : value;
    }

    private Boolean getBooleanNullable(ResultSet resultSet, String columnName) throws SQLException {
        boolean value = resultSet.getBoolean(columnName);
        return resultSet.wasNull() ? null : value;
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private RaF raFWithId(RaF raF, long generatedId) {
        return new RaF(
                generatedId,
                raF.afName(),
                raF.afDir(),
                raF.afType(),
                raF.afExecute(),
                raF.afSource(),
                raF.afCreated(),
                raF.afUpdated(),
                raF.raOrgSender(),
                raF.afNum()
        );
    }
}
