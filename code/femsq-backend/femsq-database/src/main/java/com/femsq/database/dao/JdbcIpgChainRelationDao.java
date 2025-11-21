package com.femsq.database.dao;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.IpgChainRelation;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.StringJoiner;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC-реализация {@link IpgChainRelationDao}.
 */
public class JdbcIpgChainRelationDao implements IpgChainRelationDao {

    private static final Logger log = Logger.getLogger(JdbcIpgChainRelationDao.class.getName());
    private static final String TABLE_BASE_NAME = "ipgChRl";

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;

    public JdbcIpgChainRelationDao(ConnectionFactory connectionFactory, DatabaseConfigurationService configurationService) {
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
    public Optional<IpgChainRelation> findById(int relationKey) {
        String sql = "SELECT ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr FROM " + getTableName() + " WHERE ipgcrKey = ?";
        log.log(Level.FINE, "Executing findById for ipgcrKey={0}", relationKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, relationKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return Optional.of(mapRelation(resultSet));
                }
                return Optional.empty();
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findById", exception);
            throw new DaoException("Не удалось получить связь цепочки " + relationKey, exception);
        }
    }

    @Override
    public List<IpgChainRelation> findByChain(int chainKey) {
        String sql = "SELECT ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr FROM " + getTableName() + " WHERE ipgcrChain = ? ORDER BY ipgcrKey";
        log.fine(() -> "Executing findByChain for ipgcrChain=" + chainKey);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, chainKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgChainRelation> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRelation(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByChain", exception);
            throw new DaoException("Не удалось получить связи для цепочки " + chainKey, exception);
        }
    }

    @Override
    public List<IpgChainRelation> findByChains(Collection<Integer> chainKeys) {
        if (chainKeys == null || chainKeys.isEmpty()) {
            return List.of();
        }
        StringJoiner placeholders = new StringJoiner(", ");
        chainKeys.forEach(key -> placeholders.add("?"));
        String sql = "SELECT ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr FROM " + getTableName()
                + " WHERE ipgcrChain IN (" + placeholders + ") ORDER BY ipgcrChain, ipgcrKey";
        log.fine(() -> "Executing findByChains for keys=" + chainKeys);
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int index = 1;
            for (Integer key : chainKeys) {
                statement.setInt(index++, key);
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                List<IpgChainRelation> result = new ArrayList<>();
                while (resultSet.next()) {
                    result.add(mapRelation(resultSet));
                }
                return List.copyOf(result);
            }
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findByChains", exception);
            throw new DaoException("Не удалось получить связи для цепочек", exception);
        }
    }

    @Override
    public List<IpgChainRelation> findAll() {
        String sql = "SELECT ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr FROM " + getTableName() + " ORDER BY ipgcrKey";
        log.fine("Executing findAll for ipgChRl");
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            List<IpgChainRelation> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(mapRelation(resultSet));
            }
            return List.copyOf(result);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw exception;
        } catch (SQLException exception) {
            log.log(Level.SEVERE, "Failed to execute findAll", exception);
            throw new DaoException("Не удалось получить список связей цепочек", exception);
        }
    }

    private IpgChainRelation mapRelation(ResultSet resultSet) throws SQLException {
        return new IpgChainRelation(
                resultSet.getInt("ipgcrKey"),
                resultSet.getInt("ipgcrChain"),
                resultSet.getInt("ipgcrIpg"),
                resultSet.getObject("ipgcrUtPlGr", Integer.class)
        );
    }
}
