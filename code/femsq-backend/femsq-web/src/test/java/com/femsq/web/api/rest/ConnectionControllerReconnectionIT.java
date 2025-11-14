package com.femsq.web.api.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.web.api.dto.ConnectionConfigResponse;
import com.femsq.web.api.dto.ConnectionStatusResponse;
import com.femsq.web.api.dto.ConnectionTestRequest;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Locale;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

/**
 * Интеграционные тесты для проверки переподключения к базе данных через ConnectionController.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ConnectionControllerReconnectionIT {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int localPort;

    private String originalUserHome;
    private Path temporaryHome;
    private DatabaseConfigurationProperties baseConfiguration;

    @BeforeAll
    void setUpUserHomeAndConfiguration() throws Exception {
        assumeTrue(isDatabaseConfigured(), "Переменные окружения FEMSQ_DB_* не заданы, тест пропущен");

        baseConfiguration = configurationFromEnv();

        originalUserHome = System.getProperty("user.home");
        temporaryHome = Files.createTempDirectory("femsq-home-reconnection-it");
        System.setProperty("user.home", temporaryHome.toString());

        writeConfiguration(baseConfiguration);
    }

    @AfterAll
    void restoreUserHome() throws Exception {
        if (originalUserHome != null) {
            System.setProperty("user.home", originalUserHome);
        }
        if (temporaryHome != null) {
            Files.walk(temporaryHome)
                    .sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (Exception ignored) {
                            // Игнорируем ошибки удаления временных файлов
                        }
                    });
        }
    }

    @BeforeEach
    void resetConfiguration() {
        writeConfiguration(baseConfiguration);
    }

    @Test
    void getStatus_WhenConnected_ReturnsConnectedStatus() {
        ResponseEntity<ConnectionStatusResponse> response = restTemplate.exchange(
                "/api/v1/connection/status",
                HttpMethod.GET,
                HttpEntity.EMPTY,
                ConnectionStatusResponse.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.connected()).isTrue();
        assertThat(body.schema()).isEqualTo(baseConfiguration.schema());
        assertThat(body.database()).isEqualTo(baseConfiguration.database());
    }

    @Test
    void testConnection_WithValidConfiguration_ReturnsSuccess() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                baseConfiguration.host(),
                baseConfiguration.port(),
                baseConfiguration.database(),
                baseConfiguration.schema(),
                baseConfiguration.username(),
                baseConfiguration.password(),
                baseConfiguration.authMode());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<ConnectionTestRequest> entity = new HttpEntity<>(request, headers);

        ResponseEntity<ConnectionStatusResponse> response = restTemplate.exchange(
                "/api/v1/connection/test",
                HttpMethod.POST,
                entity,
                ConnectionStatusResponse.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.connected()).isTrue();
        assertThat(body.schema()).isEqualTo(baseConfiguration.schema());
        assertThat(body.error()).isNull();
    }

    @Test
    void testConnection_WithInvalidHost_ReturnsError() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                "invalid-host",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "wrong-password",
                "credentials");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<ConnectionTestRequest> entity = new HttpEntity<>(request, headers);

        ResponseEntity<ConnectionStatusResponse> response = restTemplate.exchange(
                "/api/v1/connection/test",
                HttpMethod.POST,
                entity,
                ConnectionStatusResponse.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.connected()).isFalse();
        assertThat(body.error()).isNotNull();
    }

    @Test
    void applyConfiguration_WithValidConfiguration_ReconnectsSuccessfully() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                baseConfiguration.host(),
                baseConfiguration.port(),
                baseConfiguration.database(),
                baseConfiguration.schema(),
                baseConfiguration.username(),
                baseConfiguration.password(),
                baseConfiguration.authMode());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<ConnectionTestRequest> entity = new HttpEntity<>(request, headers);

        ResponseEntity<ConnectionStatusResponse> response = restTemplate.exchange(
                "/api/v1/connection/apply",
                HttpMethod.POST,
                entity,
                ConnectionStatusResponse.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.connected()).isTrue();
        assertThat(body.schema()).isEqualTo(baseConfiguration.schema());
        assertThat(body.message()).contains("Конфигурация применена");
    }

    @Test
    void applyConfiguration_WithDifferentSchema_ReconnectsToNewSchema() {
        // Применяем конфигурацию с той же схемой (для теста переподключения)
        ConnectionTestRequest request = new ConnectionTestRequest(
                baseConfiguration.host(),
                baseConfiguration.port(),
                baseConfiguration.database(),
                baseConfiguration.schema(), // Используем ту же схему
                baseConfiguration.username(),
                baseConfiguration.password(),
                baseConfiguration.authMode());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<ConnectionTestRequest> entity = new HttpEntity<>(request, headers);

        // Первое применение
        ResponseEntity<ConnectionStatusResponse> firstResponse = restTemplate.exchange(
                "/api/v1/connection/apply",
                HttpMethod.POST,
                entity,
                ConnectionStatusResponse.class);

        assertThat(firstResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse firstBody = firstResponse.getBody();
        assertThat(firstBody).isNotNull();
        assertThat(firstBody.connected()).isTrue();

        // Проверяем, что статус обновился
        ResponseEntity<ConnectionStatusResponse> statusResponse = restTemplate.exchange(
                "/api/v1/connection/status",
                HttpMethod.GET,
                HttpEntity.EMPTY,
                ConnectionStatusResponse.class);

        assertThat(statusResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionStatusResponse statusBody = statusResponse.getBody();
        assertThat(statusBody).isNotNull();
        assertThat(statusBody.connected()).isTrue();
        assertThat(statusBody.schema()).isEqualTo(baseConfiguration.schema());
    }

    @Test
    void getConfig_AfterApply_ReturnsUpdatedConfiguration() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                baseConfiguration.host(),
                baseConfiguration.port(),
                baseConfiguration.database(),
                baseConfiguration.schema(),
                baseConfiguration.username(),
                baseConfiguration.password(),
                baseConfiguration.authMode());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<ConnectionTestRequest> entity = new HttpEntity<>(request, headers);

        // Применяем конфигурацию
        restTemplate.exchange(
                "/api/v1/connection/apply",
                HttpMethod.POST,
                entity,
                ConnectionStatusResponse.class);

        // Получаем конфигурацию
        ResponseEntity<ConnectionConfigResponse> configResponse = restTemplate.exchange(
                "/api/v1/connection/config",
                HttpMethod.GET,
                HttpEntity.EMPTY,
                ConnectionConfigResponse.class);

        assertThat(configResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        ConnectionConfigResponse configBody = configResponse.getBody();
        assertThat(configBody).isNotNull();
        assertThat(configBody.host()).isEqualTo(baseConfiguration.host());
        assertThat(configBody.port()).isEqualTo(baseConfiguration.port());
        assertThat(configBody.database()).isEqualTo(baseConfiguration.database());
        assertThat(configBody.schema()).isEqualTo(baseConfiguration.schema());
        assertThat(configBody.username()).isEqualTo(baseConfiguration.username());
        assertThat(configBody.authMode()).isEqualTo(baseConfiguration.authMode());
    }

    private boolean isDatabaseConfigured() {
        String password = System.getenv("FEMSQ_DB_PASSWORD");
        return password != null && !password.isBlank();
    }

    private DatabaseConfigurationProperties configurationFromEnv() {
        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "FishEye");
        String schema = envOr("FEMSQ_DB_SCHEMA", "ags_test");
        String authMode = envOr("FEMSQ_DB_AUTH_MODE", "credentials").toLowerCase(Locale.ROOT);
        String username = "credentials".equals(authMode) ? envOr("FEMSQ_DB_USER", "sa") : null;
        String password = "credentials".equals(authMode) ? System.getenv("FEMSQ_DB_PASSWORD") : null;
        return new DatabaseConfigurationProperties(host, port, database, schema, username, password, authMode);
    }

    private void writeConfiguration(DatabaseConfigurationProperties configuration) {
        ConfigurationFileManager fileManager = new ConfigurationFileManager();
        ConfigurationValidator validator = new ConfigurationValidator();
        DatabaseConfigurationService configurationService = new DatabaseConfigurationService(fileManager, validator);
        configurationService.saveConfig(configuration);
    }

    private String envOr(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }
}


