package com.femsq.database.dao;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.RaFtS;
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
 * JDBC-реализация {@link RaFtSDao} для работы с таблицей {@code ags.ra_ft_s}.
 */
public class JdbcRaFtSDao implements RaFtSDao {

    private static final Logger log = Logger.getLogger(JdbcRaFtSDao.class.getName());
    private static final String TABLE_NAME = "ags.ra_ft_s";

    private final ConnectionFactory connectionFactory;

    public JdbcRaFtSDao(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public Optional<RaFtS> findById(int ftSKey) {
        String sql = "SELECT ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_created, ft_s_updated, ft_s_period " +
                "FROM " + TABLE_NAME + " WHERE ft_s_key = ?";
        log.log(Level.FINE, "Executing findById for ftSKey={0}", ftSKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftSKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRaFtS(resultSet));
                }
                return Optional.empty();
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить источник с идентификатором " + ftSKey, exception);
        }
    }

    @Override
    public List<RaFtS> findAll() {
        String sql = "SELECT ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_created, ft_s_updated, ft_s_period " +
                "FROM " + TABLE_NAME + " ORDER BY ft_s_key";
        log.fine("Executing findAll for ra_ft_s");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<RaFtS> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRaFtS(resultSet));
            }
            return List.copyOf(result);
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список источников", exception);
        }
    }

    @Override
    public List<RaFtS> findByFileType(int fileType) {
        String sql = "SELECT ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_created, ft_s_updated, ft_s_period " +
                "FROM " + TABLE_NAME + " WHERE ft_s_type = ? ORDER BY ft_s_num";
        log.log(Level.FINE, "Executing findByFileType for fileType={0}", fileType);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, fileType);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaFtS> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRaFtS(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByFileType", exception);
            throw new DaoException("Не удалось получить источники для типа файла " + fileType, exception);
        }
    }

    @Override
    public List<RaFtS> findBySheetType(int sheetType) {
        String sql = "SELECT ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_created, ft_s_updated, ft_s_period " +
                "FROM " + TABLE_NAME + " WHERE ft_s_sheet_type = ? ORDER BY ft_s_num";
        log.log(Level.FINE, "Executing findBySheetType for sheetType={0}", sheetType);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, sheetType);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<RaFtS> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRaFtS(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findBySheetType", exception);
            throw new DaoException("Не удалось получить источники для типа источника " + sheetType, exception);
        }
    }

    @Override
    public long count() {
        String sql = "SELECT COUNT(*) FROM " + TABLE_NAME;
        log.fine("Executing count for ra_ft_s");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getLong(1);
            }
            return 0L;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество источников", exception);
        }
    }

    @Override
    public RaFtS create(RaFtS raFtS) {
        Objects.requireNonNull(raFtS, "raFtS");
        String sql = "INSERT INTO " + TABLE_NAME + " (ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_period) VALUES (?, ?, ?, ?)";
        log.log(Level.INFO, "Creating file source type={0}, num={1}", new Object[]{raFtS.ftSType(), raFtS.ftSNum()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, raFtS.ftSType());
            statement.setInt(2, raFtS.ftSNum());
            statement.setInt(3, raFtS.ftSSheetType());
            setNStringNullable(statement, 4, raFtS.ftSPeriod());
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int generatedId = generatedKeys.getInt(1);
                    return raFtSWithId(raFtS, generatedId);
                }
                throw new DaoException("Не удалось получить идентификатор созданного источника");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create", exception);
            throw new DaoException("Не удалось создать источник", exception);
        }
    }

    @Override
    public RaFtS update(RaFtS raFtS) {
        Objects.requireNonNull(raFtS, "raFtS");
        if (raFtS.ftSKey() == null) {
            throw new DaoException("Для обновления источника необходим идентификатор");
        }
        String sql = "UPDATE " + TABLE_NAME
                + " SET ft_s_type = ?, ft_s_num = ?, ft_s_sheet_type = ?, ft_s_period = ?, ft_s_updated = GETDATE() "
                + "WHERE ft_s_key = ?";
        log.log(Level.INFO, "Updating file source {0}", raFtS.ftSKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, raFtS.ftSType());
            statement.setInt(2, raFtS.ftSNum());
            statement.setInt(3, raFtS.ftSSheetType());
            setNStringNullable(statement, 4, raFtS.ftSPeriod());
            statement.setInt(5, raFtS.ftSKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Источник с идентификатором " + raFtS.ftSKey() + " не найден");
            }
            return raFtS;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update", exception);
            throw new DaoException("Не удалось обновить источник", exception);
        }
    }

    @Override
    public boolean deleteById(int ftSKey) {
        String sql = "DELETE FROM " + TABLE_NAME + " WHERE ft_s_key = ?";
        log.log(Level.INFO, "Deleting file source {0}", ftSKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, ftSKey);
            int deleted = statement.executeUpdate();
            return deleted > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete", exception);
            throw new DaoException("Не удалось удалить источник " + ftSKey, exception);
        }
    }

    private void setNStringNullable(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.NVARCHAR);
        } else {
            statement.setNString(index, value);
        }
    }

    private RaFtS mapRaFtS(ResultSet resultSet) throws SQLException {
        return new RaFtS(
                resultSet.getInt("ft_s_key"),
                resultSet.getInt("ft_s_type"),
                resultSet.getInt("ft_s_num"),
                resultSet.getInt("ft_s_sheet_type"),
                toLocalDateTime(resultSet.getTimestamp("ft_s_created")),
                toLocalDateTime(resultSet.getTimestamp("ft_s_updated")),
                resultSet.getNString("ft_s_period")
        );
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private RaFtS raFtSWithId(RaFtS raFtS, int generatedId) {
        return new RaFtS(
                generatedId,
                raFtS.ftSType(),
                raFtS.ftSNum(),
                raFtS.ftSSheetType(),
                raFtS.ftSCreated(),
                raFtS.ftSUpdated(),
                raFtS.ftSPeriod()
        );
    }
}
