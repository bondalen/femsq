package com.femsq.database.connection;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Objects;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Factory responsible for creating JDBC connections to MS SQL Server using prepared configuration
 * and authentication providers.
 */
public class ConnectionFactory implements AutoCloseable {

    private static final Logger log = Logger.getLogger(ConnectionFactory.class.getName());

    private final JdbcConnector connector;
    private final DatabaseConfigurationService configurationService;
    private final AuthenticationProviderFactory providerFactory;
    private final boolean ownsConnector;

    /**
     * Создает фабрику с дефолтным пулом HikariCP и стандартной фабрикой провайдеров аутентификации.
     */
    public ConnectionFactory(DatabaseConfigurationService configurationService) {
        this(new HikariJdbcConnector(), configurationService, AuthenticationProviderFactory.withDefaults(), true);
    }

    public ConnectionFactory(DatabaseConfigurationService configurationService, AuthenticationProviderFactory providerFactory) {
        this(new HikariJdbcConnector(), configurationService, providerFactory, true);
    }

    /**
     * @param connector             реализация подключения JDBC
     * @param configurationService  сервис доступа к конфигурации базы данных
     */
    public ConnectionFactory(JdbcConnector connector, DatabaseConfigurationService configurationService) {
        this(connector, configurationService, AuthenticationProviderFactory.withDefaults(), false);
    }

    public ConnectionFactory(JdbcConnector connector, DatabaseConfigurationService configurationService, AuthenticationProviderFactory providerFactory) {
        this(connector, configurationService, providerFactory, false);
    }

    private ConnectionFactory(JdbcConnector connector, DatabaseConfigurationService configurationService, AuthenticationProviderFactory providerFactory, boolean ownsConnector) {
        this.connector = Objects.requireNonNull(connector, "connector");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
        this.providerFactory = Objects.requireNonNull(providerFactory, "providerFactory");
        this.ownsConnector = ownsConnector;
    }

    /**
     * Создает подключение, используя конфигурацию, загруженную из {@link DatabaseConfigurationService}, и фабрику провайдеров.
     *
     * @return активное JDBC соединение
     */
    public Connection createConnection() {
        try {
            DatabaseConfigurationProperties configuration = configurationService.loadConfig();
            AuthenticationProvider provider = providerFactory.create(configuration);
            return createConnection(configuration, provider);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            // Пробрасываем MissingConfigurationException дальше для правильной обработки в ApiExceptionHandler
            throw exception;
        }
    }

    /**
     * Создает подключение, используя конфигурацию, загруженную из {@link DatabaseConfigurationService} и переданный провайдер.
     *
     * @param provider стратегия аутентификации
     * @return активное JDBC соединение
     */
    public Connection createConnection(AuthenticationProvider provider) {
        try {
            DatabaseConfigurationProperties configuration = configurationService.loadConfig();
            return createConnection(configuration, provider);
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            // Пробрасываем MissingConfigurationException дальше для правильной обработки в ApiExceptionHandler
            throw exception;
        }
    }

    /**
     * Создает подключение на основе переданной конфигурации.
     *
     * @param configuration валидированные параметры подключения
     * @param provider      стратегия аутентификации
     * @return активное JDBC соединение
     */
    public Connection createConnection(DatabaseConfigurationProperties configuration, AuthenticationProvider provider) {
        Objects.requireNonNull(configuration, "configuration");
        Objects.requireNonNull(provider, "provider");

        Properties properties = provider.buildProperties(configuration);
        properties.putIfAbsent("databaseName", configuration.database());

        String jdbcUrl = buildJdbcUrl(configuration);
        log.log(Level.INFO, "Opening JDBC connection to {0} using provider {1}", new Object[]{jdbcUrl, provider.getName()});
        
        // DEBUG: Log all JDBC properties
        log.log(Level.INFO, "=== JDBC Connection Properties ===");
        for (String key : properties.stringPropertyNames()) {
            String value = properties.getProperty(key);
            // Mask password
            if (key.toLowerCase().contains("password")) {
                value = "***";
            }
            log.log(Level.INFO, "  {0} = {1}", new Object[]{key, value});
        }
        log.log(Level.INFO, "==================================");
        
        try {
            return connector.connect(jdbcUrl, properties);
        } catch (SQLException sqlException) {
            log.log(Level.SEVERE, "Failed to open JDBC connection to " + jdbcUrl, sqlException);
            throw new ConnectionFactoryException("Не удалось установить соединение с базой данных", sqlException);
        }
    }

    /**
     * Формирует JDBC URL для MS SQL Server, соответствующий настройкам проекта.
     */
    public String buildJdbcUrl(DatabaseConfigurationProperties configuration) {
        return String.format("jdbc:sqlserver://%s:%d;encrypt=false;trustServerCertificate=true",
                configuration.host(),
                configuration.port() == null ? 1433 : configuration.port());
    }

    /**
     * Выполняет проверку подключения, закрывая соединение после проверки.
     *
     * @param provider     стратегия аутентификации
     * @param timeoutSeconds таймаут проверки в секундах
     * @return {@code true} если соединение успешно создано и признано валидным
     */
    public boolean testConnection(AuthenticationProvider provider, int timeoutSeconds) {
        try (Connection connection = createConnection(provider)) {
            return connection != null && connection.isValid(timeoutSeconds);
        } catch (SQLException sqlException) {
            log.log(Level.WARNING, "Connection validation failed", sqlException);
            return false;
        }
    }

    public boolean testConnection(int timeoutSeconds) {
        try (Connection connection = createConnection()) {
            return connection != null && connection.isValid(timeoutSeconds);
        } catch (SQLException sqlException) {
            log.log(Level.WARNING, "Connection validation failed", sqlException);
            return false;
        }
    }

    /**
     * Принудительно закрывает пул соединений для переподключения.
     * <p>
     * После вызова этого метода, при следующем создании соединения пул будет
     * пересоздан с актуальной конфигурацией из {@link DatabaseConfigurationService}.
     * </p>
     * <p>
     * Используется для динамического переподключения без перезапуска приложения.
     * </p>
     */
    public void reloadConnectionPool() {
        try {
            connector.close();
            log.log(Level.INFO, "Connection pool closed, will be recreated on next connection");
        } catch (Exception exception) {
            log.log(Level.WARNING, "Failed to close connection pool for reload", exception);
        }
    }

    @Override
    public void close() {
        try {
            connector.close();
        } catch (Exception exception) {
            if (ownsConnector) {
                log.log(Level.WARNING, "Failed to close JDBC connector", exception);
            }
        }
    }
}
