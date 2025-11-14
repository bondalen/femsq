package com.femsq.database.config;

import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.Properties;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * Валидатор параметров конфигурации подключения к базе данных.
 */
public class ConfigurationValidator {

    private static final Logger log = Logger.getLogger(ConfigurationValidator.class.getName());
    private static final Pattern HOST_PATTERN = Pattern.compile("^[a-zA-Z0-9-_.]+$");
    private static final Pattern SCHEMA_PATTERN = Pattern.compile("^[a-zA-Z0-9_]+$");
    private static final String DEFAULT_SCHEMA = "ags_test";
    private static final Set<String> SUPPORTED_AUTH_MODES = Set.of("credentials", "windows-integrated", "kerberos");

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
        validateSchema(properties.schema());

        validateOptional("username", properties.username());
        validateOptional("password", properties.password());
        validateAuthMode(properties);
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
        String schema = normalizeSchema(properties.getProperty("schema"));
        String username = properties.getProperty("username");
        String password = properties.getProperty("password");
        String authMode = normalizeAuthMode(properties.getProperty("authMode"), username);

        var config = new DatabaseConfigurationService.DatabaseConfigurationProperties(host, port, database, schema, username, password, authMode);
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

    private void validateAuthMode(DatabaseConfigurationService.DatabaseConfigurationProperties properties) {
        String authMode = properties.authMode();
        if (authMode == null || authMode.isBlank()) {
            throw new IllegalArgumentException("Режим аутентификации (authMode) не может быть пустым");
        }
        String normalized = authMode.trim().toLowerCase(Locale.ROOT);
        if (!SUPPORTED_AUTH_MODES.contains(normalized)) {
            throw new IllegalArgumentException("Неизвестный режим аутентификации: " + authMode);
        }
        if ("credentials".equals(normalized)) {
            if (properties.username() == null || properties.username().isBlank()) {
                throw new IllegalArgumentException("username обязателен для режима credentials");
            }
            if (properties.password() == null || properties.password().isBlank()) {
                throw new IllegalArgumentException("password обязателен для режима credentials");
            }
        }
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

    private void validateSchema(String schema) {
        if (schema != null && !schema.isBlank()) {
            if (!SCHEMA_PATTERN.matcher(schema).matches()) {
                throw new IllegalArgumentException("Schema содержит недопустимые символы: " + schema);
            }
            if (schema.length() > 128) {
                throw new IllegalArgumentException("Schema превышает максимально допустимую длину 128 символов: " + schema);
            }
        }
    }

    private String normalizeSchema(String rawSchema) {
        if (rawSchema == null || rawSchema.isBlank()) {
            return DEFAULT_SCHEMA;
        }
        return rawSchema.trim();
    }

    private String normalizeAuthMode(String rawAuthMode, String username) {
        if (rawAuthMode == null || rawAuthMode.isBlank()) {
            return (username != null && !username.isBlank()) ? "credentials" : "windows-integrated";
        }
        return rawAuthMode.trim().toLowerCase(Locale.ROOT);
    }
}
