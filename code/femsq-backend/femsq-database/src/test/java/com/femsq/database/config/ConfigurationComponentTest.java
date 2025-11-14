package com.femsq.database.config;

import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Properties;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

class ConfigurationComponentTest {

    private String originalUserHome;
    private Path temporaryHome;

    private ConfigurationFileManager fileManager;
    private ConfigurationValidator validator;
    private DatabaseConfigurationService configurationService;

    @BeforeEach
    void setUp() throws IOException {
        originalUserHome = System.getProperty("user.home");
        temporaryHome = Files.createTempDirectory("femsq-home-test");
        System.setProperty("user.home", temporaryHome.toString());

        fileManager = new ConfigurationFileManager();
        validator = new ConfigurationValidator();
        configurationService = new DatabaseConfigurationService(fileManager, validator);
    }

    @AfterEach
    void tearDown() throws IOException {
        if (originalUserHome != null) {
            System.setProperty("user.home", originalUserHome);
        }
        if (temporaryHome != null) {
            Files.walk(temporaryHome)
                    .sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException ignored) {
                            // Игнорируем ошибки очистки временных файлов
                        }
                    });
        }
    }

    @Test
    void loadPropertiesReturnsEmptyWhenFileMissing() {
        Properties properties = fileManager.loadProperties();
        assertTrue(properties.isEmpty(), "При отсутствии файла конфигурации ожидаются пустые свойства");
    }

    @Test
    void loadConfigThrowsWhenFileMissing() {
        assertThrows(DatabaseConfigurationService.MissingConfigurationException.class, () -> configurationService.loadConfig());
    }

    @Test
    void writePropertiesCreatesFileAndPersistsValues() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.server.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");
        properties.setProperty("username", "alex");
        properties.setProperty("password", "secret");
        properties.setProperty("authMode", "credentials");

        fileManager.writeProperties(properties);

        Properties loaded = fileManager.loadProperties();
        assertEquals("db.server.local", loaded.getProperty("host"));
        assertEquals("1433", loaded.getProperty("port"));
        assertEquals("femsq", loaded.getProperty("database"));
        assertEquals("alex", loaded.getProperty("username"));
        assertEquals("secret", loaded.getProperty("password"));
        assertEquals("credentials", loaded.getProperty("authMode"));
    }

    @Test
    void ensureDirectoryWithPermissionsCreatesDirectory() {
        fileManager.ensureDirectoryWithPermissions();
        Path configurationDirectory = fileManager.resolveConfigPath().getParent();
        assertNotNull(configurationDirectory);
        assertTrue(Files.exists(configurationDirectory), "Должна существовать директория ~/.femsq после вызова ensureDirectoryWithPermissions");
    }

    @Nested
    @DisplayName("ConfigurationValidator негативные сценарии")
    class ConfigurationValidatorNegativeTests {

        @Test
        void validatorRejectsInvalidHost() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "bad host name", 1433, "femsq", null, "alex", "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("Host"));
        }

        @Test
        void validatorRejectsInvalidPort() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 70000, "femsq", null, "alex", "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("Port"));
        }

        @Test
        void validatorRejectsMissingDatabase() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 1433, null, null, "alex", "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("database"));
        }

        @Test
        void validatorRejectsEmptyHost() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "", 1433, "femsq", null, "alex", "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("Host"));
        }

        @Test
        void validatorRejectsTooLongUsername() {
            String longUsername = "x".repeat(256);
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 1433, "femsq", null, longUsername, "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("username"));
        }

        @Test
        void validatorRejectsNullPort() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", null, "femsq", null, "alex", "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("Port"));
        }

        @Test
        void validatorRejectsUnknownAuthMode() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 1433, "femsq", null, "alex", "secret", "unknown-mode");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("режим"));
        }

        @Test
        void validatorRequiresCredentialsUsername() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 1433, "femsq", null, null, "secret", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("username"));
        }

        @Test
        void validatorRequiresCredentialsPassword() {
            DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                    new DatabaseConfigurationService.DatabaseConfigurationProperties(
                            "db.local", 1433, "femsq", null, "alex", null, "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.validate(invalidConfig));
            assertTrue(exception.getMessage().contains("password"));
        }

        @Test
        void mapThrowsWhenPortIsNotNumeric() {
            Properties properties = new Properties();
            properties.setProperty("host", "db.local");
            properties.setProperty("port", "not-a-number");
            properties.setProperty("database", "femsq");
            properties.setProperty("authMode", "credentials");

            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class, () -> validator.map(properties));
            assertTrue(exception.getMessage().contains("Port"));
        }
    }

    @Test
    void mapCreatesValidatedConfiguration() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");
        properties.setProperty("username", "alex");
        properties.setProperty("password", "pwd");
        properties.setProperty("authMode", "credentials");

        DatabaseConfigurationService.DatabaseConfigurationProperties configuration = validator.map(properties);

        assertEquals("db.local", configuration.host());
        assertEquals(1433, configuration.port());
        assertEquals("femsq", configuration.database());
        assertEquals("ags_test", configuration.schema());
        assertEquals("alex", configuration.username());
        assertEquals("pwd", configuration.password());
        assertEquals("credentials", configuration.authMode());
    }

    @Test
    void mapDefaultsAuthModeBasedOnUsername() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");
        properties.setProperty("username", "alex");
        properties.setProperty("password", "pwd");

        DatabaseConfigurationService.DatabaseConfigurationProperties configuration = validator.map(properties);
        assertEquals("credentials", configuration.authMode());
    }

    @Test
    void mapDefaultsAuthModeToWindowsIntegratedWhenNoCredentials() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");

        DatabaseConfigurationService.DatabaseConfigurationProperties configuration = validator.map(properties);
        assertEquals("windows-integrated", configuration.authMode());
    }

    @Test
    void serviceSaveAndLoadRoundTrip() {
        DatabaseConfigurationService.DatabaseConfigurationProperties configuration =
                new DatabaseConfigurationService.DatabaseConfigurationProperties(
                        "db.roundtrip.local", 1433, "femsq", "ags_test", "alex", "secret", "credentials");

        configurationService.saveConfig(configuration);

        DatabaseConfigurationService.DatabaseConfigurationProperties loaded = configurationService.loadConfig();

        assertEquals(configuration.host(), loaded.host());
        assertEquals(configuration.port(), loaded.port());
        assertEquals(configuration.database(), loaded.database());
        assertEquals(configuration.schema(), loaded.schema());
        assertEquals(configuration.username(), loaded.username());
        assertEquals(configuration.password(), loaded.password());
        assertEquals(configuration.authMode(), loaded.authMode());
    }

    @Test
    void mapDefaultsSchemaToAgsTest() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");
        properties.setProperty("username", "alex");
        properties.setProperty("password", "pwd");
        properties.setProperty("authMode", "credentials");

        DatabaseConfigurationService.DatabaseConfigurationProperties configuration = validator.map(properties);
        assertEquals("ags_test", configuration.schema());
    }

    @Test
    void mapUsesSchemaFromProperties() {
        Properties properties = new Properties();
        properties.setProperty("host", "db.local");
        properties.setProperty("port", "1433");
        properties.setProperty("database", "femsq");
        properties.setProperty("schema", "ags");
        properties.setProperty("username", "alex");
        properties.setProperty("password", "pwd");
        properties.setProperty("authMode", "credentials");

        DatabaseConfigurationService.DatabaseConfigurationProperties configuration = validator.map(properties);
        assertEquals("ags", configuration.schema());
    }

    @Test
    void validatorRejectsInvalidSchema() {
        DatabaseConfigurationService.DatabaseConfigurationProperties invalidConfig =
                new DatabaseConfigurationService.DatabaseConfigurationProperties(
                        "db.local", 1433, "femsq", "invalid-schema-name", "alex", "secret", "credentials");

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class, () -> validator.validate(invalidConfig));
        assertTrue(exception.getMessage().contains("Schema"));
    }
}
