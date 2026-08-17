package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnNum;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
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
