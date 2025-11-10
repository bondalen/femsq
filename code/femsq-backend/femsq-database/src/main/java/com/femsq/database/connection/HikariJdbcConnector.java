package com.femsq.database.connection;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC connector backed by {@link HikariDataSource}. Reconfigures the pool when JDBC URL or
 * connection properties change.
 */
public class HikariJdbcConnector implements JdbcConnector {

    private static final Logger log = Logger.getLogger(HikariJdbcConnector.class.getName());

    private final Object poolLock = new Object();
    private HikariDataSource dataSource;
    private String currentJdbcUrl;
    private Properties currentProperties;

    @Override
    public Connection connect(String url, Properties properties) throws SQLException {
        Objects.requireNonNull(url, "url");
        Objects.requireNonNull(properties, "properties");
        ensureDataSource(url, properties);
        return dataSource.getConnection();
    }

    private void ensureDataSource(String url, Properties properties) {
        synchronized (poolLock) {
            if (requiresRebuild(url, properties)) {
                closeQuietly();
                HikariConfig config = buildConfig(url, properties);
                dataSource = new HikariDataSource(config);
                currentJdbcUrl = url;
                currentProperties = copyProperties(properties);
                log.log(Level.INFO, "Initialized Hikari pool for {0}", url);
            }
        }
    }

    private boolean requiresRebuild(String url, Properties properties) {
        if (dataSource == null) {
            return true;
        }
        if (!Objects.equals(currentJdbcUrl, url)) {
            return true;
        }
        return !properties.equals(currentProperties);
    }

    private HikariConfig buildConfig(String url, Properties properties) {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(url);
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setPoolName("FEMSQ-HikariPool");
        config.setConnectionTimeout(10_000);
        config.setValidationTimeout(5_000);
        config.setIdleTimeout(600_000);
        config.setMaxLifetime(1_800_000);

        properties.forEach((key, value) -> {
            String propertyKey = (String) key;
            String propertyValue = String.valueOf(value);
            if ("user".equals(propertyKey)) {
                config.setUsername(propertyValue);
            } else if ("password".equals(propertyKey)) {
                config.setPassword(propertyValue);
            } else {
                config.addDataSourceProperty(propertyKey, propertyValue);
            }
        });
        return config;
    }

    private Properties copyProperties(Properties properties) {
        Properties copy = new Properties();
        copy.putAll(properties);
        return copy;
    }

    private void closeQuietly() {
        if (dataSource != null) {
            try {
                dataSource.close();
            } catch (Exception ignored) {
                // Игнорируем исключения при закрытии пула
            }
        }
    }

    @Override
    public void close() {
        synchronized (poolLock) {
            closeQuietly();
            dataSource = null;
            currentJdbcUrl = null;
            currentProperties = null;
        }
    }
}
