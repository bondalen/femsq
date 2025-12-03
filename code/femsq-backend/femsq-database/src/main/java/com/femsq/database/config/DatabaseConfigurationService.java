package com.femsq.database.config;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Сервис управления конфигурацией подключения к MS SQL Server.
 * <p>
 * Реализует сценарии чтения и записи файла {@code ~/.femsq/database.properties},
 * а также использует {@link ConfigurationValidator} для проверки корректности параметров.
 * </p>
 * <p>
 * Использует кэширование для уменьшения количества обращений к файловой системе.
 * Кэш автоматически инвалидируется при изменении файла конфигурации (проверка по lastModified).
 * </p>
 */
public class DatabaseConfigurationService {

    private static final Logger log = Logger.getLogger(DatabaseConfigurationService.class.getName());

    private final ConfigurationFileManager fileManager;
    private final ConfigurationValidator validator;

    // Кэш конфигурации с проверкой изменений файла
    private volatile DatabaseConfigurationProperties cachedConfig;
    private volatile long configFileLastModified = 0;

    /**
     * Создает сервис конфигурации с требуемыми зависимостями.
     *
     * @param fileManager утилита для работы с файлом конфигурации
     * @param validator   валидатор параметров подключения
     */
    public DatabaseConfigurationService(ConfigurationFileManager fileManager, ConfigurationValidator validator) {
        this.fileManager = fileManager;
        this.validator = validator;
    }

    /**
     * Загружает конфигурацию подключения из файла пользователя.
     * <p>
     * Использует кэширование для уменьшения количества обращений к файловой системе.
     * Кэш автоматически инвалидируется при изменении файла конфигурации.
     * </p>
     *
     * @return валидированные свойства подключения
     */
    public DatabaseConfigurationProperties loadConfig() {
        Path configPath = fileManager.resolveConfigPath();
        
        // Проверяем, существует ли файл
        if (!Files.exists(configPath)) {
            log.log(Level.WARNING, "Database configuration file {0} is missing or empty", configPath);
            throw new MissingConfigurationException(configPath);
        }

        // Проверяем кэш с синхронизацией для thread-safety
        synchronized (this) {
            try {
                long currentLastModified = Files.getLastModifiedTime(configPath).toMillis();
                
                // Если файл не изменился и кэш существует - возвращаем кэш
                if (cachedConfig != null && currentLastModified == configFileLastModified) {
                    log.log(Level.FINE, "Using cached database configuration from {0}", configPath);
                    return cachedConfig;
                }
                
                // Файл изменился или кэш пуст - загружаем заново
                log.log(Level.INFO, "Loading database configuration from {0}", configPath);
                var rawProperties = fileManager.loadProperties();
                if (rawProperties.isEmpty()) {
                    log.log(Level.WARNING, "Database configuration file {0} is missing or empty", configPath);
                    throw new MissingConfigurationException(configPath);
                }
                
                DatabaseConfigurationProperties config = validator.map(rawProperties);
                
                // Обновляем кэш
                cachedConfig = config;
                configFileLastModified = currentLastModified;
                
                return config;
            } catch (java.io.IOException ioException) {
                log.log(Level.SEVERE, "Failed to check file modification time for {0}", configPath);
                // При ошибке проверки времени модификации - загружаем без кэша
                var rawProperties = fileManager.loadProperties();
                if (rawProperties.isEmpty()) {
                    throw new MissingConfigurationException(configPath);
                }
                return validator.map(rawProperties);
            }
        }
    }

    /**
     * Сохраняет конфигурацию подключения в файл пользователя.
     * <p>
     * После сохранения инвалидирует кэш, чтобы следующая загрузка использовала новые данные.
     * </p>
     *
     * @param properties валидированные свойства подключения
     */
    public void saveConfig(DatabaseConfigurationProperties properties) {
        validator.validate(properties);
        Path configPath = fileManager.resolveConfigPath();
        log.log(Level.INFO, "Saving database configuration to {0}", configPath);
        var rawProperties = new java.util.Properties();
        rawProperties.setProperty("host", properties.host());
        rawProperties.setProperty("port", properties.port() == null ? "" : properties.port().toString());
        rawProperties.setProperty("database", properties.database());
        if (properties.schema() != null) {
            rawProperties.setProperty("schema", properties.schema());
        }
        if (properties.username() != null) {
            rawProperties.setProperty("username", properties.username());
        }
        if (properties.password() != null) {
            rawProperties.setProperty("password", properties.password());
        }
        if (properties.authMode() != null) {
            rawProperties.setProperty("authMode", properties.authMode().toLowerCase(Locale.ROOT));
        }
        fileManager.writeProperties(rawProperties);
        
        // Инвалидируем кэш после сохранения
        synchronized (this) {
            cachedConfig = null;
            configFileLastModified = 0;
            log.log(Level.FINE, "Cache invalidated after saving configuration");
        }
    }

    /**
     * Контейнер с параметрами подключения к базе данных.
     * <p>
     * На этапе прототипа представлен в виде вложенной записи; в дальнейшем будет
     * перемещен в отдельный класс при необходимости расширения функциональности.
     * </p>
     *
     * @param host     хост MS SQL Server
     * @param port     порт подключения
     * @param database имя базы данных
     * @param schema   имя схемы (опционально, по умолчанию ags_test)
     * @param username имя пользователя (опционально)
     * @param password пароль (опционально)
     * @param authMode режим аутентификации (credentials, windows-integrated, kerberos)
     */
    public record DatabaseConfigurationProperties(
            String host,
            Integer port,
            String database,
            String schema,
            String username,
            String password,
            String authMode) {
    }

    /**
     * Исключение, сигнализирующее об отсутствии пользовательского файла конфигурации.
     */
    public static class MissingConfigurationException extends RuntimeException {

        /**
         * Создает исключение с указанием пути отсутствующего файла.
         *
         * @param configPath путь к ожидаемому файлу конфигурации
         */
        public MissingConfigurationException(Path configPath) {
            super("Файл конфигурации подключения к базе данных не найден: " + configPath);
        }
    }
}
