package com.femsq.database.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.FileAttribute;
import java.nio.file.attribute.PosixFilePermission;
import java.nio.file.attribute.PosixFilePermissions;
import java.util.Objects;
import java.util.Properties;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Менеджер файлов конфигурации FEMSQ.
 * <p>
 * Отвечает за создание директорий, установку безопасных прав доступа и
 * чтение/запись файла {@code ~/.femsq/database.properties}.
 * </p>
 */
public class ConfigurationFileManager {

    private static final Logger log = Logger.getLogger(ConfigurationFileManager.class.getName());
    private static final Path CONFIG_DIR = Paths.get(System.getProperty("user.home"), ".femsq");
    private static final Path CONFIG_FILE = CONFIG_DIR.resolve("database.properties");
    private static final Set<PosixFilePermission> CONFIG_DIRECTORY_PERMISSIONS =
            PosixFilePermissions.fromString("rwx------");
    private static final Set<PosixFilePermission> CONFIG_FILE_PERMISSIONS =
            PosixFilePermissions.fromString("rw-------");

    /**
     * Возвращает путь к файлу конфигурации.
     *
     * @return путь к {@code database.properties}
     */
    public Path resolveConfigPath() {
        return CONFIG_FILE;
    }

    /**
     * Загружает свойства из файла конфигурации.
     *
     * @return прочитанные свойства
     */
    public Properties loadProperties() {
        log.log(Level.INFO, "Loading configuration properties from {0}", CONFIG_FILE);
        Properties properties = new Properties();
        if (Files.notExists(CONFIG_FILE)) {
            log.log(Level.WARNING, "Configuration file {0} does not exist. Returning empty properties.", CONFIG_FILE);
            return properties;
        }

        try (var inputStream = Files.newInputStream(CONFIG_FILE)) {
            properties.load(inputStream);
            return properties;
        } catch (IOException ioException) {
            log.log(Level.SEVERE, "Failed to load configuration from " + CONFIG_FILE, ioException);
            throw new ConfigurationFileOperationException("Не удалось прочитать файл конфигурации", ioException);
        }
    }

    /**
     * Записывает свойства в файл конфигурации.
     *
     * @param properties свойства для сохранения
     */
    public void writeProperties(Properties properties) {
        Objects.requireNonNull(properties, "properties");
        log.log(Level.INFO, "Writing configuration properties to {0}", CONFIG_FILE);

        ensureDirectoryWithPermissions();
        var fileAttributes = new FileAttribute<?>[]{PosixFilePermissions.asFileAttribute(CONFIG_FILE_PERMISSIONS)};

        try {
            if (Files.notExists(CONFIG_FILE)) {
                try {
                    Files.createFile(CONFIG_FILE, fileAttributes);
                } catch (UnsupportedOperationException unsupportedOperationException) {
                    Files.createFile(CONFIG_FILE);
                }
            }
        } catch (IOException createException) {
            log.log(Level.SEVERE, "Failed to create configuration file " + CONFIG_FILE, createException);
            throw new ConfigurationFileOperationException("Не удалось создать файл конфигурации", createException);
        }

        try (var outputStream = Files.newOutputStream(CONFIG_FILE)) {
            properties.store(outputStream, "FEMSQ database connection settings");
            try {
                Files.setPosixFilePermissions(CONFIG_FILE, CONFIG_FILE_PERMISSIONS);
            } catch (UnsupportedOperationException ignored) {
                // Игнорируем на платформах без POSIX прав
            }
        } catch (IOException ioException) {
            log.log(Level.SEVERE, "Failed to write configuration to " + CONFIG_FILE, ioException);
            throw new ConfigurationFileOperationException("Не удалось записать файл конфигурации", ioException);
        }
    }

    /**
     * Обеспечивает наличие директории конфигурации и устанавливает безопасные права доступа.
     */
    public void ensureDirectoryWithPermissions() {
        log.log(Level.FINE, "Ensuring configuration directory {0} exists with secure permissions", CONFIG_DIR);
        if (Files.exists(CONFIG_DIR)) {
            applyDirectoryPermissions(CONFIG_DIR);
            return;
        }

        try {
            Files.createDirectories(CONFIG_DIR);
            applyDirectoryPermissions(CONFIG_DIR);
        } catch (IOException ioException) {
            log.log(Level.SEVERE, "Failed to create configuration directory " + CONFIG_DIR, ioException);
            throw new ConfigurationFileOperationException("Не удалось создать директорию конфигурации", ioException);
        }
    }

    private void applyDirectoryPermissions(Path directory) {
        try {
            Files.setPosixFilePermissions(directory, CONFIG_DIRECTORY_PERMISSIONS);
        } catch (UnsupportedOperationException unsupportedOperationException) {
            log.log(Level.FINE, "POSIX permissions are not supported for path {0}", directory);
        } catch (IOException ioException) {
            log.log(Level.WARNING, "Failed to apply secure permissions to {0}", directory);
        }
    }

    /**
     * Исключение операции над файлом конфигурации.
     */
    public static class ConfigurationFileOperationException extends RuntimeException {
        public ConfigurationFileOperationException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
