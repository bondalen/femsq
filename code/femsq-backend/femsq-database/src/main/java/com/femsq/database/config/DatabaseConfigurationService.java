package com.femsq.database.config;

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
 */
public class DatabaseConfigurationService {

    private static final Logger log = Logger.getLogger(DatabaseConfigurationService.class.getName());

    private final ConfigurationFileManager fileManager;
    private final ConfigurationValidator validator;

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
     *
     * @return валидированные свойства подключения
     */
    public DatabaseConfigurationProperties loadConfig() {
        Path configPath = fileManager.resolveConfigPath();
        log.log(Level.INFO, "Loading database configuration from {0}", configPath);
        var rawProperties = fileManager.loadProperties();
        return validator.map(rawProperties);
    }

    /**
     * Сохраняет конфигурацию подключения в файл пользователя.
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
     * @param username имя пользователя (опционально)
     * @param password пароль (опционально)
     * @param authMode режим аутентификации (credentials, windows-integrated, kerberos)
     */
    public record DatabaseConfigurationProperties(
            String host,
            Integer port,
            String database,
            String username,
            String password,
            String authMode) {
    }
}
