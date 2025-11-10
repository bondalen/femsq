package com.femsq.database.config;

import java.util.Objects;
import java.util.Optional;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * Валидатор параметров конфигурации подключения к базе данных.
 */
public class ConfigurationValidator {

    private static final Logger log = Logger.getLogger(ConfigurationValidator.class.getName());
    private static final Pattern HOST_PATTERN = Pattern.compile("^[a-zA-Z0-9-_.]+$");

    /**
     * Валидирует переданные свойства и выбрасывает {@link IllegalArgumentException} при ошибках.
     *
     * @param properties свойства подключения
     */
    public void validate(DatabaseConfigurationService.DatabaseConfigurationProperties properties) {
        Objects.requireNonNull(properties, "properties");
        log.log(Level.FINE, "Validating database configuration: host={0}, database={1}", new Object[] {properties.host(), properties.database()});

        validateHost(properties.host());
        validatePort(properties.port());
        validateRequired("database", properties.database());

        validateOptional("username", properties.username());
        validateOptional("password", properties.password());
    }

    /**
     * Создает объект конфигурации на основе raw {@link Properties}.
     *
     * @param properties исходные свойства
     * @return валидированное представление конфигурации
     */
    public DatabaseConfigurationService.DatabaseConfigurationProperties map(Properties properties) {
        Objects.requireNonNull(properties, "properties");
        log.log(Level.FINE, "Mapping raw properties to DatabaseConfigurationProperties");

        String host = properties.getProperty("host");
        Integer port = parsePort(properties.getProperty("port"));
        String database = properties.getProperty("database");
        String username = properties.getProperty("username");
        String password = properties.getProperty("password");

        var config = new DatabaseConfigurationService.DatabaseConfigurationProperties(host, port, database, username, password);
        validate(config);
        return config;
    }

    private void validateHost(String host) {
        if (host == null || host.isBlank()) {
            throw new IllegalArgumentException("Host (host) не может быть пустым");
        }
        if (!HOST_PATTERN.matcher(host).matches()) {
            throw new IllegalArgumentException("Host содержит недопустимые символы: " + host);
        }
    }

    private void validatePort(Integer port) {
        if (port == null) {
            throw new IllegalArgumentException("Port (port) должен быть указан");
        }
        if (port < 1 || port > 65535) {
            throw new IllegalArgumentException("Port должен находиться в диапазоне 1-65535: " + port);
        }
    }

    private void validateRequired(String fieldName, String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " не может быть пустым");
        }
    }

    private void validateOptional(String fieldName, String value) {
        Optional.ofNullable(value)
                .filter(v -> !v.isBlank())
                .ifPresent(v -> {
                    if (v.length() > 255) {
                        throw new IllegalArgumentException(fieldName + " превышает максимально допустимую длину 255 символов");
                    }
                });
    }

    private Integer parsePort(String portValue) {
        if (portValue == null || portValue.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(portValue);
        } catch (NumberFormatException exception) {
            throw new IllegalArgumentException("Port должен быть целым числом", exception);
        }
    }
}
