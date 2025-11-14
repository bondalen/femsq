package com.femsq.web.api.rest;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.ConnectionFactoryException;
import com.femsq.database.connection.ConnectionManager;
import com.femsq.database.connection.HikariJdbcConnector;
import com.femsq.web.api.dto.ConnectionConfigResponse;
import com.femsq.web.api.dto.ConnectionStatusResponse;
import com.femsq.web.api.dto.ConnectionTestRequest;
import jakarta.validation.Valid;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для управления подключением к базе данных.
 */
@RestController
@RequestMapping("/api/v1/connection")
public class ConnectionController {

    private static final Logger log = Logger.getLogger(ConnectionController.class.getName());

    private final ConnectionFactory connectionFactory;
    private final DatabaseConfigurationService configurationService;
    private final AuthenticationProviderFactory providerFactory;
    private final ConfigurationValidator configurationValidator;
    private final ConnectionManager connectionManager;

    public ConnectionController(
            ConnectionFactory connectionFactory,
            DatabaseConfigurationService configurationService,
            AuthenticationProviderFactory providerFactory,
            ConfigurationValidator configurationValidator,
            ConnectionManager connectionManager) {
        this.connectionFactory = connectionFactory;
        this.configurationService = configurationService;
        this.providerFactory = providerFactory;
        this.configurationValidator = configurationValidator;
        this.connectionManager = connectionManager;
    }

    /**
     * Возвращает текущее состояние подключения к базе данных.
     */
    @GetMapping("/status")
    public ConnectionStatusResponse getStatus() {
        log.info("Handling GET /api/v1/connection/status");
        try {
            DatabaseConfigurationProperties config = configurationService.loadConfig();
            boolean connected = connectionFactory.testConnection(5);
            
            return new ConnectionStatusResponse(
                    connected,
                    config.schema(),
                    config.database(),
                    connected ? "Подключение активно" : "Подключение не установлено",
                    null
            );
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            return new ConnectionStatusResponse(
                    false,
                    null,
                    null,
                    "Конфигурация не найдена",
                    exception.getMessage()
            );
        } catch (ConnectionFactoryException exception) {
            log.log(Level.WARNING, "Failed to test connection", exception);
            return new ConnectionStatusResponse(
                    false,
                    null,
                    null,
                    "Ошибка проверки подключения",
                    exception.getMessage()
            );
        }
    }

    /**
     * Проверяет подключение к базе данных без сохранения конфигурации.
     * <p>
     * Валидирует конфигурацию, создает временное подключение для тестирования
     * и возвращает результат проверки. Конфигурация не сохраняется.
     * </p>
     */
    @PostMapping("/test")
    public ConnectionStatusResponse testConnection(@Valid @RequestBody ConnectionTestRequest request) {
        log.info("Handling POST /api/v1/connection/test");
        ConnectionFactory testFactory = null;
        try {
            // Преобразуем DTO в конфигурацию
            DatabaseConfigurationProperties testConfig = toConfigurationProperties(request);
            
            // Валидируем конфигурацию перед тестированием
            configurationValidator.validate(testConfig);
            
            // Создаем провайдер аутентификации
            AuthenticationProvider provider = providerFactory.create(testConfig);
            
            // Создаем временный ConnectionFactory для тестирования
            TemporaryConfigurationService tempConfigService = new TemporaryConfigurationService(testConfig);
            testFactory = new ConnectionFactory(
                    new HikariJdbcConnector(),
                    tempConfigService,
                    providerFactory
            );
            
            // Тестируем подключение с таймаутом 5 секунд
            boolean connected = testFactory.testConnection(provider, 5);
            
            if (connected) {
                log.info(() -> String.format("Connection test successful: %s:%d/%s/%s",
                        testConfig.host(), testConfig.port(), testConfig.database(), testConfig.schema()));
                return new ConnectionStatusResponse(
                        true,
                        testConfig.schema(),
                        testConfig.database(),
                        "Подключение успешно",
                        null
                );
            } else {
                log.warning(() -> String.format("Connection test failed: %s:%d/%s/%s",
                        testConfig.host(), testConfig.port(), testConfig.database(), testConfig.schema()));
                return new ConnectionStatusResponse(
                        false,
                        testConfig.schema(),
                        testConfig.database(),
                        "Не удалось установить подключение",
                        "Проверка подключения не прошла. Проверьте параметры подключения."
                );
            }
        } catch (IllegalArgumentException exception) {
            log.log(Level.WARNING, "Invalid configuration for connection test", exception);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (ConnectionFactoryException exception) {
            log.log(Level.WARNING, "Connection test failed with exception", exception);
            String errorMessage = extractErrorMessage(exception);
            return new ConnectionStatusResponse(
                    false,
                    request.schema(),
                    request.database(),
                    "Ошибка подключения",
                    errorMessage
            );
        } catch (Exception exception) {
            log.log(Level.SEVERE, "Unexpected error during connection test", exception);
            return new ConnectionStatusResponse(
                    false,
                    request.schema(),
                    request.database(),
                    "Непредвиденная ошибка",
                    exception.getMessage()
            );
        } finally {
            // Гарантируем закрытие временного ConnectionFactory
            if (testFactory != null) {
                try {
                    testFactory.close();
                } catch (Exception exception) {
                    log.log(Level.WARNING, "Failed to close test connection factory", exception);
                }
            }
        }
    }
    
    /**
     * Извлекает понятное сообщение об ошибке из исключения.
     */
    private String extractErrorMessage(ConnectionFactoryException exception) {
        String message = exception.getMessage();
        Throwable cause = exception.getCause();
        
        if (cause != null) {
            String causeMessage = cause.getMessage();
            if (causeMessage != null && !causeMessage.isBlank()) {
                // Упрощаем сообщение об ошибке для пользователя
                if (causeMessage.contains("Login failed")) {
                    return "Ошибка аутентификации. Проверьте имя пользователя и пароль.";
                } else if (causeMessage.contains("network") || causeMessage.contains("timeout")) {
                    return "Ошибка сети. Проверьте доступность сервера и параметры подключения.";
                } else if (causeMessage.contains("database")) {
                    return "База данных не найдена. Проверьте имя базы данных.";
                }
                return causeMessage;
            }
        }
        
        return message != null ? message : "Неизвестная ошибка подключения";
    }

    /**
     * Применяет новую конфигурацию подключения и переподключается.
     * <p>
     * Использует {@link ConnectionManager} для валидации, тестирования, сохранения
     * конфигурации и переподключения к базе данных без перезапуска приложения.
     * </p>
     */
    @PostMapping("/apply")
    public ConnectionStatusResponse applyConfiguration(@Valid @RequestBody ConnectionTestRequest request) {
        log.info("Handling POST /api/v1/connection/apply");
        try {
            DatabaseConfigurationProperties newConfig = toConfigurationProperties(request);
            
            // Используем ConnectionManager для переподключения
            // Он выполнит: валидацию, тестирование, сохранение и переподключение
            connectionManager.reconnect(newConfig);
            
            log.info(() -> String.format("Configuration applied and reconnected: %s:%d/%s/%s",
                    newConfig.host(), newConfig.port(), newConfig.database(), newConfig.schema()));
            
            return new ConnectionStatusResponse(
                    true,
                    newConfig.schema(),
                    newConfig.database(),
                    "Конфигурация применена и подключение установлено",
                    null
            );
        } catch (IllegalArgumentException exception) {
            log.log(Level.WARNING, "Invalid configuration for apply", exception);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (ConnectionFactoryException exception) {
            log.log(Level.WARNING, "Failed to apply configuration and reconnect", exception);
            String errorMessage = extractErrorMessage(exception);
            return new ConnectionStatusResponse(
                    false,
                    request.schema(),
                    request.database(),
                    "Ошибка применения конфигурации",
                    errorMessage
            );
        } catch (Exception exception) {
            log.log(Level.SEVERE, "Unexpected error during configuration apply", exception);
            return new ConnectionStatusResponse(
                    false,
                    request.schema(),
                    request.database(),
                    "Непредвиденная ошибка при применении конфигурации",
                    exception.getMessage()
            );
        }
    }

    /**
     * Возвращает текущую конфигурацию подключения (без пароля).
     */
    @GetMapping("/config")
    public ConnectionConfigResponse getConfig() {
        log.info("Handling GET /api/v1/connection/config");
        try {
            DatabaseConfigurationProperties config = configurationService.loadConfig();
            return new ConnectionConfigResponse(
                    config.host(),
                    config.port(),
                    config.database(),
                    config.schema(),
                    config.username(),
                    config.authMode()
            );
        } catch (DatabaseConfigurationService.MissingConfigurationException exception) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Конфигурация не найдена", exception);
        }
    }

    private DatabaseConfigurationProperties toConfigurationProperties(ConnectionTestRequest request) {
        return new DatabaseConfigurationProperties(
                request.host(),
                request.port(),
                request.database(),
                request.schema(),
                request.username(),
                request.password(),
                request.authMode()
        );
    }

    /**
     * Временный сервис конфигурации для тестирования подключения без сохранения.
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


