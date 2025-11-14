package com.femsq.database.connection;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import java.sql.SQLException;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Менеджер подключений к базе данных с поддержкой динамического переподключения.
 * <p>
 * Управляет {@link ConnectionFactory} и обеспечивает возможность переподключения
 * к базе данных без перезапуска приложения. При переподключении закрывает старые
 * соединения в пуле и пересоздает пул с новой конфигурацией.
 * </p>
 */
public class ConnectionManager {

    private static final Logger log = Logger.getLogger(ConnectionManager.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;
    private final ConfigurationValidator configurationValidator;
    private final AuthenticationProviderFactory providerFactory;

    /**
     * Создает менеджер подключений.
     *
     * @param connectionFactory       фабрика подключений
     * @param configurationService    сервис конфигурации
     * @param configurationValidator  валидатор конфигурации
     * @param providerFactory         фабрика провайдеров аутентификации
     */
    public ConnectionManager(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService,
            ConfigurationValidator configurationValidator,
            AuthenticationProviderFactory providerFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.configurationService = Objects.requireNonNull(configurationService, "configurationService");
        this.configurationValidator = Objects.requireNonNull(configurationValidator, "configurationValidator");
        this.providerFactory = Objects.requireNonNull(providerFactory, "providerFactory");
    }

    /**
     * Выполняет переподключение к базе данных с новой конфигурацией.
     * <p>
     * Процесс переподключения:
     * <ol>
     *   <li>Валидирует новую конфигурацию</li>
     *   <li>Тестирует подключение с новой конфигурацией</li>
     *   <li>Сохраняет конфигурацию в файл</li>
     *   <li>Закрывает старые соединения в пуле</li>
     *   <li>При следующем создании соединения пул пересоздастся автоматически</li>
     * </ol>
     * </p>
     *
     * @param newConfig новая конфигурация подключения
     * @throws IllegalArgumentException если конфигурация невалидна
     * @throws ConnectionFactoryException если не удалось установить подключение
     */
    public void reconnect(DatabaseConfigurationProperties newConfig) {
        Objects.requireNonNull(newConfig, "newConfig");
        log.log(Level.INFO, "Starting reconnection to {0}:{1}/{2}/{3}",
                new Object[]{
                        newConfig.host(),
                        newConfig.port(),
                        newConfig.database(),
                        newConfig.schema()
                });

        // 1. Валидация новой конфигурации
        configurationValidator.validate(newConfig);
        log.log(Level.FINE, "Configuration validated successfully");

        // 2. Тестирование подключения
        testConnection(newConfig);
        log.log(Level.INFO, "Connection test successful");

        // 3. Сохранение конфигурации в файл
        configurationService.saveConfig(newConfig);
        log.log(Level.INFO, "Configuration saved to file");

        // 4. Закрытие старых соединений в пуле
        // При следующем вызове createConnection() пул пересоздастся автоматически
        // благодаря механизму HikariJdbcConnector.ensureDataSource()
        connectionFactory.reloadConnectionPool();
        log.log(Level.INFO, "Old connections closed, pool will be recreated on next connection");
    }

    /**
     * Тестирует подключение с указанной конфигурацией.
     *
     * @param config конфигурация для тестирования
     * @throws ConnectionFactoryException если подключение не удалось
     */
    private void testConnection(DatabaseConfigurationProperties config) {
        AuthenticationProvider provider = providerFactory.create(config);
        
        // Создаем временный ConnectionFactory для тестирования
        TemporaryConfigurationService tempConfigService = new TemporaryConfigurationService(config);
        ConnectionFactory testFactory = new ConnectionFactory(
                new HikariJdbcConnector(),
                tempConfigService,
                providerFactory
        );
        
        try {
            boolean connected = testFactory.testConnection(provider, 5);
            if (!connected) {
                throw new ConnectionFactoryException(
                        "Не удалось установить подключение с новой конфигурацией",
                        new SQLException("Connection test failed"));
            }
        } catch (ConnectionFactoryException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new ConnectionFactoryException(
                    "Ошибка при тестировании подключения: " + exception.getMessage(), exception);
        } finally {
            testFactory.close();
        }
    }

    /**
     * Возвращает текущую конфигурацию подключения.
     *
     * @return текущая конфигурация
     */
    public DatabaseConfigurationProperties getCurrentConfig() {
        return configurationService.loadConfig();
    }

    /**
     * Проверяет, установлено ли подключение к базе данных.
     *
     * @return {@code true} если подключение активно
     */
    public boolean isConnected() {
        try {
            return connectionFactory.testConnection(5);
        } catch (Exception exception) {
            log.log(Level.FINE, "Connection check failed", exception);
            return false;
        }
    }

    /**
     * Временный сервис конфигурации для тестирования подключения.
     */
    private static class TemporaryConfigurationService extends DatabaseConfigurationService {
        private final DatabaseConfigurationProperties configuration;

        TemporaryConfigurationService(DatabaseConfigurationProperties configuration) {
            super(null, null);
            this.configuration = configuration;
        }

        @Override
        public DatabaseConfigurationProperties loadConfig() {
            return configuration;
        }
    }
}


