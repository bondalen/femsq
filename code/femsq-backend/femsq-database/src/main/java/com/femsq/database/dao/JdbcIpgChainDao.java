package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.IpgChain;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link IpgChainDao}.
 */
public class JdbcIpgChainDao implements IpgChainDao {

    private static final Logger log = Logger.getLogger(JdbcIpgChainDao.class.getName());
    private static final String TABLE_BASE_NAME = "ipgCh";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcIpgChainDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
    }

    private String resolveSchema() {
        try {
            String schema = configurationService.loadConfig().schema();
            if (schema == null || schema.trim().isEmpty()) {
                log.log(Level.WARNING, "Schema not configured, using default schema 'ags'");
                return "ags";
            }
            return schema.trim();
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            log.log(Level.WARNING, "Configuration not found, using default schema 'ags'", exception);
            return "ags";
        }
    }

    private String getTableName() {
        return resolveSchema() + "." + TABLE_BASE_NAME;
    }

    @Override
    public Optional<IpgChain> findById(int chainKey) {
        String sql = "SELECT ipgcKey, ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy FROM " + getTableName() + " WHERE ipgcKey = ?";
        log.log(Level.FINE, "Executing findById for ipgcKey={0}", chainKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, chainKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapChain(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить цепочку с идентификатором " + chainKey, exception);
        }
    }

    @Override
    public List<IpgChain> findAll() {
        String sql = "SELECT ipgcKey, ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy FROM " + getTableName() + " ORDER BY ipgcKey";
        log.fine("Executing findAll for ipgCh");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<IpgChain> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapChain(resultSet));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список цепочек инвестиционных программ", exception);
        }
    }

    @Override
    public List<IpgChain> findAll(int page, int size, String sortField, String sortDirection, String nameFilter, Integer yearFilter) {
        String safeSortField = validateSortField(sortField);
        String safeSortDirection = "desc".equalsIgnoreCase(sortDirection) ? "DESC" : "ASC";
        int offset = page * size;
        StringBuilder sql = new StringBuilder("SELECT ipgcKey, ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy FROM ")
                .append(getTableName());

        List<Object> params = new ArrayList<>();
        List<Integer> sqlTypes = new ArrayList<>();

        String normalizedFilter = normalizeNameFilter(nameFilter);
        boolean hasWhere = false;
        if (normalizedFilter != null) {
            sql.append(" WHERE LOWER(ipgcName) LIKE ?");
            params.add(likePattern(normalizedFilter));
            hasWhere = true;
        }
        if (yearFilter != null) {
            sql.append(hasWhere ? " AND" : " WHERE").append(" ipgcYyyy = ?");
            params.add(yearFilter);
            sqlTypes.add(java.sql.Types.INTEGER);
        }

        sql.append(" ORDER BY ").append(safeSortField).append(' ').append(safeSortDirection)
                .append(" OFFSET ").append(offset).append(" ROWS FETCH NEXT ").append(size).append(" ROWS ONLY");

        String finalSql = sql.toString();
        log.fine(() -> String.format("Executing paged findAll for ipgCh: page=%d, size=%d, sort=%s %s, filter=%s, year=%s",
                page, size, safeSortField, safeSortDirection, normalizedFilter, yearFilter));
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(finalSql)) {
            int index = 1;
            for (Object param : params) {
                if (param instanceof String value) {
                    statement.setNString(index++, value);
                } else if (param instanceof Integer value) {
                    statement.setInt(index++, value);
                } else {
                    statement.setObject(index++, param);
                }
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgChain> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapChain(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute paged findAll", exception);
            log.log(Level.SEVERE, "SQL: " + finalSql, exception);
            throw new DaoException("Не удалось получить список цепочек с пагинацией", exception);
        }
    }

    @Override
    public long count(String nameFilter, Integer yearFilter) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM ").append(getTableName());
        List<Object> params = new ArrayList<>();
        String normalizedFilter = normalizeNameFilter(nameFilter);
        boolean hasWhere = false;
        if (normalizedFilter != null) {
            sql.append(" WHERE LOWER(ipgcName) LIKE ?");
            params.add(likePattern(normalizedFilter));
            hasWhere = true;
        }
        if (yearFilter != null) {
            sql.append(hasWhere ? " AND" : " WHERE").append(" ipgcYyyy = ?");
            params.add(yearFilter);
        }
        String finalSql = sql.toString();
        log.fine(() -> String.format("Executing count for ipgCh (filter=%s, year=%s)", normalizedFilter, yearFilter));
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(finalSql)) {
            int index = 1;
            for (Object param : params) {
                if (param instanceof String value) {
                    statement.setNString(index++, value);
                } else if (param instanceof Integer value) {
                    statement.setInt(index++, value);
                }
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getLong(1);
                }
                return 0L;
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute count", exception);
            throw new DaoException("Не удалось подсчитать количество цепочек", exception);
        }
    }

    private String validateSortField(String sortField) {
        if (sortField == null || sortField.trim().isEmpty()) {
            return "ipgcKey";
        }
        String normalized = sortField.trim();
        switch (normalized.toLowerCase(Locale.ROOT)) {
            case "ipgcckey":
            case "ipgckey":
                return "ipgcKey";
            case "ipgcname":
                return "ipgcName";
            case "ipgcstnetipg":
                return "ipgcStNetIpg";
            case "ipgcipglate":
                return "ipgcIpgLate";
            case "ipgcyyyy":
                return "ipgcYyyy";
            default:
                log.warning(() -> "Invalid sort field: " + normalized + ", using default ipgcKey");
                return "ipgcKey";
        }
    }

    private String normalizeNameFilter(String nameFilter) {
        if (nameFilter == null) {
            return null;
        }
        String trimmed = nameFilter.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return trimmed.toLowerCase(Locale.ROOT);
    }

    private String likePattern(String normalizedFilter) {
        return "%" + normalizedFilter + "%";
    }

    private IpgChain mapChain(ResultSet resultSet) throws SQLException {
        return new IpgChain(
                resultSet.getInt("ipgcKey"),
                resultSet.getNString("ipgcName"),
                resultSet.getObject("ipgcStNetIpg", Integer.class),
                resultSet.getObject("ipgcIpgLate", Integer.class),
                resultSet.getObject("ipgcYyyy", Integer.class)
        );
    }
}
