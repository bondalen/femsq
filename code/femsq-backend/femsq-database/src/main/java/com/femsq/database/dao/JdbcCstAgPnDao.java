package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.CstAgPnCode;
import com.femsq.database.model.CstAgPnSiteLookup;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link CstAgPnDao}.
 */
public class JdbcCstAgPnDao implements CstAgPnDao {

    private static final Logger log = Logger.getLogger(JdbcCstAgPnDao.class.getName());
    private static final String TABLE_BASE_NAME = "cstAgPn";
    private static final String COLUMNS = "cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcCstAgPnDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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

    private String getCstAgTableName() {
        return schemaPrefix() + "cstAg";
    }

    private String getCstTableName() {
        return schemaPrefix() + "cst";
    }

    @Override
    public Optional<CstAgPn> findById(int cstapKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + getTableName() + " WHERE cstapKey = ?";
        log.log(Level.FINE, "Executing findById for cstapKey={0}", cstapKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstapKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRow(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById for cstAgPn", exception);
            throw new DaoException("Не удалось получить САК с идентификатором " + cstapKey, exception);
        }
    }

    @Override
    public List<CstAgPn> findByCstAg(int cstaKey) {
        String sql = "SELECT " + COLUMNS + " FROM " + getTableName() + " WHERE cstapCsta = ? ORDER BY cstapIpgPnN";
        log.log(Level.FINE, "Executing findByCstAg for cstaKey={0}", cstaKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstaKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstAgPn> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRow(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByCstAg for cstAgPn", exception);
            throw new DaoException("Не удалось получить САК для агента стройки " + cstaKey, exception);
        }
    }

    @Override
    public List<CstAgPnCode> findCodes(String codeFilter) {
        String normalized = normalizeFilter(codeFilter);
        StringBuilder sql = new StringBuilder(
                "SELECT p.cstapKey, p.cstapIpgPnN, p.cstapCsta, a.cstaCst, c.cstName "
                        + "FROM " + getTableName() + " p "
                        + "INNER JOIN " + getCstAgTableName() + " a ON a.cstaKey = p.cstapCsta "
                        + "LEFT JOIN " + getCstTableName() + " c ON c.cstKey = a.cstaCst "
        );
        if (normalized != null) {
            sql.append("WHERE LOWER(p.cstapIpgPnN) LIKE ? ");
        }
        sql.append("ORDER BY p.cstapIpgPnN");
        String finalSql = sql.toString();
        log.fine(() -> "Executing findCodes for cstAgPn filter=" + normalized);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(finalSql)) {
            if (normalized != null) {
                statement.setNString(1, "%" + normalized + "%");
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstAgPnCode> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(new CstAgPnCode(
                            resultSet.getInt("cstapKey"),
                            resultSet.getNString("cstapIpgPnN"),
                            resultSet.getInt("cstapCsta"),
                            resultSet.getInt("cstaCst"),
                            resultSet.getNString("cstName")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findCodes for cstAgPn", exception);
            throw new DaoException("Не удалось получить список САК по коду", exception);
        }
    }

    @Override
    public List<CstAgPnSiteLookup> findSiteLookups(int cstKey) {
        String sql = "SELECT p.cstapKey, p.cstapIpgPnN, a.cstaKey, "
                + "CONCAT(c.ogaNm, N' · ', p.cstapIpgPnN) AS agentLabel "
                + "FROM " + getTableName() + " p "
                + "INNER JOIN " + getCstAgTableName() + " a ON a.cstaKey = p.cstapCsta "
                + "LEFT JOIN " + schemaPrefix() + "ogAgCs c ON c.ogaKey = a.cstaAg "
                + "WHERE a.cstaCst = ? "
                + "ORDER BY c.ogaNm, p.cstapIpgPnN";
        log.log(Level.FINE, "Executing findSiteLookups for cstKey={0}", cstKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<CstAgPnSiteLookup> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(new CstAgPnSiteLookup(
                            resultSet.getInt("cstapKey"),
                            resultSet.getNString("cstapIpgPnN"),
                            resultSet.getInt("cstaKey"),
                            resultSet.getNString("agentLabel")
                    ));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findSiteLookups for cstAgPn", exception);
            throw new DaoException("Не удалось получить САК стройки " + cstKey, exception);
        }
    }

    private String normalizeFilter(String codeFilter) {
        if (codeFilter == null) {
            return null;
        }
        String trimmed = codeFilter.trim().toLowerCase();
        return trimmed.isEmpty() ? null : trimmed;
    }

    @Override
    public CstAgPn create(CstAgPn point) {
        Objects.requireNonNull(point, "point");
        String sql = "INSERT INTO " + getTableName() + " (cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (?, ?, ?)";
        log.log(Level.INFO, "Creating cstAgPn for csta={0}, code={1}", new Object[]{point.cstapCsta(), point.cstapIpgPnN()});
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindMutable(statement, point);
            statement.executeUpdate();
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    return withId(point, generatedKeys.getInt(1));
                }
                throw new DaoException("Не удалось получить идентификатор созданной записи cstAgPn");
            }
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute create for cstAgPn", exception);
            throw new DaoException("Не удалось создать САК", exception);
        }
    }

    @Override
    public CstAgPn update(CstAgPn point) {
        Objects.requireNonNull(point, "point");
        if (point.cstapKey() == null) {
            throw new DaoException("Для обновления cstAgPn необходим идентификатор");
        }
        String sql = "UPDATE " + getTableName()
                + " SET cstapCsta = ?, cstapIpgPnN = ?, cstapOidOld = ? WHERE cstapKey = ?";
        log.log(Level.INFO, "Updating cstAgPn {0}", point.cstapKey());
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bindMutable(statement, point);
            statement.setInt(4, point.cstapKey());
            int updated = statement.executeUpdate();
            if (updated == 0) {
                throw new DaoException("САК с идентификатором " + point.cstapKey() + " не найден");
            }
            return point;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute update for cstAgPn", exception);
            throw new DaoException("Не удалось обновить САК", exception);
        }
    }

    @Override
    public boolean deleteById(int cstapKey) {
        String sql = "DELETE FROM " + getTableName() + " WHERE cstapKey = ?";
        log.log(Level.INFO, "Deleting cstAgPn {0}", cstapKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, cstapKey);
            return statement.executeUpdate() > 0;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute delete for cstAgPn", exception);
            throw new DaoException("Не удалось удалить САК " + cstapKey, exception);
        }
    }

    private void bindMutable(PreparedStatement statement, CstAgPn point) throws SQLException {
        statement.setInt(1, point.cstapCsta());
        statement.setNString(2, point.cstapIpgPnN());
        if (point.cstapOidOld() == null) {
            statement.setNull(3, Types.OTHER);
        } else {
            statement.setObject(3, point.cstapOidOld());
        }
    }

    private CstAgPn mapRow(ResultSet resultSet) throws SQLException {
        return new CstAgPn(
                resultSet.getInt("cstapKey"),
                resultSet.getInt("cstapCsta"),
                resultSet.getNString("cstapIpgPnN"),
                resultSet.getObject("cstapOidOld", UUID.class)
        );
    }

    private CstAgPn withId(CstAgPn point, int generatedId) {
        return new CstAgPn(generatedId, point.cstapCsta(), point.cstapIpgPnN(), point.cstapOidOld());
    }
}
