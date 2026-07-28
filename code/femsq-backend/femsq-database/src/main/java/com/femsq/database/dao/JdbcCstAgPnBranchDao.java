package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPnBranch;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CstAgPnBranchDao}.
 */
public class JdbcCstAgPnBranchDao implements CstAgPnBranchDao {

    private static final Logger log = Logger.getLogger(JdbcCstAgPnBranchDao.class.getName());
    private static final String TABLE_BASE_NAME = "cstAgPnBranch";
    private static final String OG_BASE_NAME = "og";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCstAgPnBranchDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String schemaPrefix() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                log.log(Level.WARNING, "Schema not configured, using default schema 'ags'");
                return "ags.";
            }
            return schema + ".";
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema", exception);
            return "ags_test.";
        }
    }

    private String getTableName() {
        return schemaPrefix() + TABLE_BASE_NAME;
    }

    private String getOgTableName() {
        return schemaPrefix() + OG_BASE_NAME;
    }

    @Override
    public Optional<CstAgPnBranch> findById(int cstapbKey) {
        String sql = selectWithName() + " WHERE b.cstapbKey = ?";
        log.log(Level.FINE, "Executing findById for cstapbKey={0}", cstapbKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstapbKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById for cstAgPnBranch", exception);
            throw new DaoException("Не удалось получить филиал САК с идентификатором " + cstapbKey, exception);
        }
    }

    @Override
    public List<CstAgPnBranch> findByCstAgPn(int cstapKey) {
        String sql = selectWithName() + " WHERE b.cstapbCstAgPn = ? ORDER BY o.ogNm, b.cstapbKey";
        log.log(Level.FINE, "Executing findByCstAgPn for cstapKey={0}", cstapKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstapKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstAgPnBranch> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByCstAgPn for cstAgPnBranch", exception);
            throw new DaoException("Не удалось получить филиалы САК " + cstapKey, exception);
        }
    }

    @Override
    public CstAgPnBranch create(CstAgPnBranch branch) {
        Objects.requireNonNull(branch, "branch");
        String sql = "INSERT INTO " + getTableName()
                + " (cstapbCstAgPn, cstapbBranch, cstapbStart, cstapbEnd) VALUES (?, ?, ?, ?)";
        log.log(Level.INFO, "Creating cstAgPnBranch for cstap={0}, branch={1}",
                new Object[]{branch.cstapbCstAgPn(), branch.cstapbBranch()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, branch);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int id = generatedKeys.getInt(1);
                    return findById(id).orElseThrow(() -> new DaoException("Не удалось прочитать созданный филиал САК " + id));
                }
                throw new DaoException("Не удалось получить идентификатор созданной записи cstAgPnBranch");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create for cstAgPnBranch", exception);
            throw new DaoException("Не удалось создать филиал САК", exception);
        }
    }

    @Override
    public CstAgPnBranch update(CstAgPnBranch branch) {
        Objects.requireNonNull(branch, "branch");
        if (branch.cstapbKey() == null) {
            throw new DaoException("Для обновления cstAgPnBranch необходим идентификатор");
        }
        String sql = "UPDATE " + getTableName()
                + " SET cstapbCstAgPn = ?, cstapbBranch = ?, cstapbStart = ?, cstapbEnd = ? WHERE cstapbKey = ?";
        log.log(Level.INFO, "Updating cstAgPnBranch {0}", branch.cstapbKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, branch);
            statement.setInt(5, branch.cstapbKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("Филиал САК с идентификатором " + branch.cstapbKey() + " не найден");
            }
            return findById(branch.cstapbKey())
                    .orElseThrow(() -> new DaoException("Не удалось прочитать обновлённый филиал САК " + branch.cstapbKey()));
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update for cstAgPnBranch", exception);
            throw new DaoException("Не удалось обновить филиал САК", exception);
        }
    }

    @Override
    public boolean deleteById(int cstapbKey) {
        String sql = "DELETE FROM " + getTableName() + " WHERE cstapbKey = ?";
        log.log(Level.INFO, "Deleting cstAgPnBranch {0}", cstapbKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstapbKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete for cstAgPnBranch", exception);
            throw new DaoException("Не удалось удалить филиал САК " + cstapbKey, exception);
        }
    }

    private String selectWithName() {
        return "SELECT b.cstapbKey, b.cstapbCstAgPn, b.cstapbBranch, b.cstapbStart, b.cstapbEnd, o.ogNm AS branchName "
                + "FROM " + getTableName() + " b "
                + "LEFT JOIN " + getOgTableName() + " o ON o.ogKey = b.cstapbBranch";
    }

    private void bindMutable(PreparedStatement statement, CstAgPnBranch branch) throws SQLException {
        statement.setInt(1, branch.cstapbCstAgPn());
        statement.setInt(2, branch.cstapbBranch());
        setDate(statement, 3, branch.cstapbStart());
        setDate(statement, 4, branch.cstapbEnd());
    }

    private void setDate(PreparedStatement statement, int index, LocalDate value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.DATE);
        } else {
            statement.setDate(index, Date.valueOf(value));
        }
    }

    private CstAgPnBranch mapRow(ResultSet resultSet) throws SQLException {
        Date start = resultSet.getDate("cstapbStart");
        Date end = resultSet.getDate("cstapbEnd");
        return new CstAgPnBranch(
                resultSet.getInt("cstapbKey"),
                resultSet.getInt("cstapbCstAgPn"),
                resultSet.getInt("cstapbBranch"),
                start == null ? null : start.toLocalDate(),
                end == null ? null : end.toLocalDate(),
                resultSet.getNString("branchName")
        );
    }
}
