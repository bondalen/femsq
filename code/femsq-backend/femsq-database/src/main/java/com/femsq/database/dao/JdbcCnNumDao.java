package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumCreate;
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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CnNumDao}.
 */
public class JdbcCnNumDao implements CnNumDao {

    private static final Logger log = Logger.getLogger(JdbcCnNumDao.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCnNumDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schema() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                return "ags";
            }
            return schema.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using schema ags", exception);
            return "ags";
        }
    }

    private String selectSql(String whereClause) {
        String s = schema();
        return "SELECT n.cnnKey, n.cnnNum, n.cnnCn, n.cnnType, t.cnntName, n.cnnNote "
                + "FROM " + s + ".cnNum AS n "
                + "LEFT JOIN " + s + ".cnNumType AS t ON n.cnnType = t.cnntKey "
                + whereClause
                + " ORDER BY n.cnnNum";
    }

    @Override
    public List<CnNum> findAll() {
        String sql = selectSql("");
        log.fine("Executing CnNum.findAll");
        return query(sql, null);
    }

    @Override
    public List<CnNum> findByCnKey(int cnKey) {
        String sql = selectSql("WHERE n.cnnCn = ?");
        log.log(Level.FINE, "Executing CnNum.findByCnKey cnKey={0}", cnKey);
        return query(sql, cnKey);
    }

    @Override
    public CnNum create(CnNumCreate input) {
        Objects.requireNonNull(input, "input");
        if (input.cnKey() <= 0) {
            throw new IllegalArgumentException("cnKey должен быть положительным: " + input.cnKey());
        }
        if (input.cnnType() <= 0) {
            throw new IllegalArgumentException("Тип номера обязателен (cnNum.cnnType NOT NULL)");
        }
        String numRaw = input.cnnNum() == null ? "" : input.cnnNum().trim();
        String numOrNull = numRaw.isEmpty() ? null : numRaw;
        String note = input.note();
        String s = schema();
        log.log(Level.INFO, "Creating cnNum cnKey={0} num={1} type={2}",
                new Object[]{input.cnKey(), numOrNull, input.cnnType()});

        try (Connection connection = connectionFactory.createConnection()) {
            if (!cnExists(connection, s, input.cnKey())) {
                throw new IllegalArgumentException("Договор cn не найден: " + input.cnKey());
            }
            if (numOrNull != null && existsOnCn(connection, s, input.cnKey(), numOrNull)) {
                throw new IllegalArgumentException(
                        "Номер «" + numOrNull + "» уже есть у cn=" + input.cnKey());
            }

            Timestamp now = Timestamp.valueOf(LocalDateTime.now());
            int cnnKey;
            String insertNum = "INSERT INTO " + s + ".cnNum (cnnNum, cnnCn, cnnType, cnnNote, cnnTimeOfEntry) "
                    + "VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(insertNum, Statement.RETURN_GENERATED_KEYS)) {
                if (numOrNull == null) {
                    statement.setNull(1, Types.NVARCHAR);
                } else {
                    statement.setNString(1, numOrNull);
                }
                statement.setInt(2, input.cnKey());
                statement.setInt(3, input.cnnType());
                if (note == null || note.isBlank()) {
                    statement.setNull(4, Types.NVARCHAR);
                } else {
                    statement.setNString(4, note.trim());
                }
                statement.setTimestamp(5, now);
                statement.executeUpdate();
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new DaoException("Не удалось получить cnnKey");
                    }
                    cnnKey = keys.getInt(1);
                }
            }

            try (PreparedStatement statement = connection.prepareStatement(selectSql("WHERE n.cnnKey = ?"))) {
                statement.setInt(1, cnnKey);
                try (ResultSet rs = statement.executeQuery()) {
                    if (rs.next()) {
                        return mapRow(rs);
                    }
                }
            }
            throw new DaoException("Созданный cnNum не найден: " + cnnKey);
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to create cnNum", exception);
            throw new DaoException("Не удалось добавить номер договора", exception);
        }
    }

    private static boolean cnExists(Connection connection, String schema, int cnKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT 1 FROM " + schema + ".cn WHERE cn_key = ?")) {
            statement.setInt(1, cnKey);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static boolean existsOnCn(Connection connection, String schema, int cnKey, String cnnNum)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT 1 FROM " + schema + ".cnNum WHERE cnnCn = ? AND LTRIM(RTRIM(cnnNum)) = ?")) {
            statement.setInt(1, cnKey);
            statement.setNString(2, cnnNum);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    private List<CnNum> query(String sql, Integer cnKey) {
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (cnKey != null) {
                statement.setInt(1, cnKey);
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CnNum> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return result;
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to query cnNum", exception);
            throw new DaoException("Не удалось прочитать номера договоров", exception);
        }
    }

    private static CnNum mapRow(ResultSet rs) throws SQLException {
        return new CnNum(
                rs.getInt("cnnKey"),
                rs.getString("cnnNum"),
                rs.getInt("cnnCn"),
                (Integer) rs.getObject("cnnType"),
                rs.getString("cnntName"),
                rs.getString("cnnNote")
        );
    }
}
