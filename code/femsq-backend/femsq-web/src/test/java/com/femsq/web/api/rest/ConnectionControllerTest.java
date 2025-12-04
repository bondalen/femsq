package com.femsq.web.api.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.femsq.database.auth.AuthenticationProvider;
import com.femsq.database.auth.AuthenticationProviderFactory;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.ConnectionFactoryException;
import com.femsq.database.connection.ConnectionManager;
import com.femsq.web.api.dto.ConnectionConfigResponse;
import com.femsq.web.api.dto.ConnectionStatusResponse;
import com.femsq.web.api.dto.ConnectionTestRequest;
import com.femsq.web.logging.ConnectionAttemptLogger;
import java.sql.SQLException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/**
 * Unit тесты для {@link ConnectionController}.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ConnectionControllerTest {

    @Mock
    private ConnectionFactory connectionFactory;

    @Mock
    private DatabaseConfigurationService configurationService;

    @Mock
    private AuthenticationProviderFactory providerFactory;

    @Mock
    private ConfigurationValidator configurationValidator;

    @Mock
    private ConnectionManager connectionManager;

    @Mock
    private AuthenticationProvider authenticationProvider;

    @Mock
    private ConnectionAttemptLogger connectionAttemptLogger;

    private ConnectionController controller;

    private DatabaseConfigurationProperties testConfig;

    @BeforeEach
    void setUp() {
        controller = new ConnectionController(
                connectionFactory,
                configurationService,
                providerFactory,
                configurationValidator,
                connectionManager,
                connectionAttemptLogger);

        testConfig = new DatabaseConfigurationProperties(
                "localhost",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "password",
                "credentials");
    }

    @Test
    void getStatus_WhenConnected_ReturnsConnectedStatus() {
        when(configurationService.loadConfig()).thenReturn(testConfig);
        when(connectionFactory.testConnection(anyInt())).thenReturn(true);

        ConnectionStatusResponse response = controller.getStatus();

        assertThat(response.connected()).isTrue();
        assertThat(response.schema()).isEqualTo("ags_test");
        assertThat(response.database()).isEqualTo("FishEye");
        assertThat(response.message()).isEqualTo("Подключение активно");
        assertThat(response.error()).isNull();
    }

    @Test
    void getStatus_WhenNotConnected_ReturnsDisconnectedStatus() {
        when(configurationService.loadConfig()).thenReturn(testConfig);
        when(connectionFactory.testConnection(anyInt())).thenReturn(false);

        ConnectionStatusResponse response = controller.getStatus();

        assertThat(response.connected()).isFalse();
        assertThat(response.schema()).isEqualTo("ags_test");
        assertThat(response.database()).isEqualTo("FishEye");
        assertThat(response.message()).isEqualTo("Подключение не установлено");
    }

    @Test
    void getStatus_WhenConfigurationMissing_ReturnsErrorStatus() {
        when(configurationService.loadConfig())
                .thenThrow(new DatabaseConfigurationService.MissingConfigurationException(
                        java.nio.file.Path.of("test.properties")));

        ConnectionStatusResponse response = controller.getStatus();

        assertThat(response.connected()).isFalse();
        assertThat(response.schema()).isNull();
        assertThat(response.database()).isNull();
        assertThat(response.message()).isEqualTo("Конфигурация не найдена");
        assertThat(response.error()).isNotNull();
    }

    @Test
    void getStatus_WhenConnectionTestFails_ReturnsErrorStatus() {
        when(configurationService.loadConfig()).thenReturn(testConfig);
        when(connectionFactory.testConnection(anyInt()))
                .thenThrow(new ConnectionFactoryException("Connection failed", new SQLException()));

        ConnectionStatusResponse response = controller.getStatus();

        assertThat(response.connected()).isFalse();
        assertThat(response.message()).isEqualTo("Ошибка проверки подключения");
        assertThat(response.error()).isNotNull();
    }

    @Test
    void testConnection_WithValidRequest_ReturnsSuccess() {
        // Этот тест требует реального подключения к БД, так как testConnection создает временный ConnectionFactory
        // Поэтому пропускаем его в unit-тестах - он покрыт integration-тестами
        // Реальная проверка выполняется в ConnectionControllerReconnectionIT
        org.junit.jupiter.api.Assumptions.assumeTrue(false, 
                "This test requires real database connection - covered by integration tests");
    }

    @Test
    void testConnection_WithInvalidRequest_ThrowsBadRequest() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                "localhost",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "password",
                "credentials");

        doThrow(new IllegalArgumentException("Invalid configuration"))
                .when(configurationValidator)
                .validate(any(DatabaseConfigurationProperties.class));

        try {
            controller.testConnection(request);
            org.junit.jupiter.api.Assertions.fail("Expected ResponseStatusException");
        } catch (ResponseStatusException exception) {
            assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(exception.getReason()).isEqualTo("Invalid configuration");
        }

        verify(connectionAttemptLogger).logAttempt(eq(request), eq(false),
                eq("Invalid configuration"), any(IllegalArgumentException.class));
    }

    @Test
    void testConnection_WhenConnectionFails_ReturnsError() {
        // Этот тест требует реального подключения к БД, так как testConnection создает временный ConnectionFactory
        // Поэтому пропускаем его в unit-тестах - он покрыт integration-тестами

        // Тест пропускается, так как требует реального подключения
        // Реальная проверка выполняется в ConnectionControllerReconnectionIT
        org.junit.jupiter.api.Assumptions.assumeTrue(false, 
                "This test requires real database connection - covered by integration tests");
    }

    @Test
    void applyConfiguration_WithValidRequest_AppliesAndReconnects() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                "localhost",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "password",
                "credentials");

        ConnectionStatusResponse response = controller.applyConfiguration(request);

        verify(connectionManager).reconnect(any(DatabaseConfigurationProperties.class));
        assertThat(response.connected()).isTrue();
        assertThat(response.schema()).isEqualTo("ags_test");
        assertThat(response.message()).isEqualTo("Конфигурация применена и подключение установлено");
        verify(connectionAttemptLogger).logAttempt(eq(request), eq(true),
                eq("Конфигурация применена и подключение установлено"), isNull());
    }

    @Test
    void applyConfiguration_WithInvalidRequest_ThrowsBadRequest() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                "localhost",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "password",
                "credentials");

        doThrow(new IllegalArgumentException("Invalid configuration"))
                .when(connectionManager)
                .reconnect(any(DatabaseConfigurationProperties.class));

        try {
            controller.applyConfiguration(request);
            org.junit.jupiter.api.Assertions.fail("Expected ResponseStatusException");
        } catch (ResponseStatusException exception) {
            assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(exception.getReason()).isEqualTo("Invalid configuration");
        }

        verify(connectionAttemptLogger).logAttempt(eq(request), eq(false),
                eq("Invalid configuration"), any(IllegalArgumentException.class));
    }

    @Test
    void applyConfiguration_WhenReconnectionFails_ReturnsError() {
        ConnectionTestRequest request = new ConnectionTestRequest(
                "localhost",
                1433,
                "FishEye",
                "ags_test",
                "sa",
                "password",
                "credentials");

        doThrow(new ConnectionFactoryException("Connection failed", new SQLException("Login failed")))
                .when(connectionManager)
                .reconnect(any(DatabaseConfigurationProperties.class));

        ConnectionStatusResponse response = controller.applyConfiguration(request);

        assertThat(response.connected()).isFalse();
        assertThat(response.error()).isNotNull();
        assertThat(response.error()).contains("аутентификации");
        verify(connectionAttemptLogger).logAttempt(eq(request), eq(false),
                eq("Ошибка аутентификации. Проверьте имя пользователя и пароль."),
                any(ConnectionFactoryException.class));
    }

    @Test
    void getConfig_WhenConfigurationExists_ReturnsConfig() {
        when(configurationService.loadConfig()).thenReturn(testConfig);

        ConnectionConfigResponse response = controller.getConfig();

        assertThat(response.host()).isEqualTo("localhost");
        assertThat(response.port()).isEqualTo(1433);
        assertThat(response.database()).isEqualTo("FishEye");
        assertThat(response.schema()).isEqualTo("ags_test");
        assertThat(response.username()).isEqualTo("sa");
        assertThat(response.authMode()).isEqualTo("credentials");
    }

    @Test
    void getConfig_WhenConfigurationMissing_ThrowsNotFound() {
        when(configurationService.loadConfig())
                .thenThrow(new DatabaseConfigurationService.MissingConfigurationException(
                        java.nio.file.Path.of("test.properties")));

        try {
            controller.getConfig();
            org.junit.jupiter.api.Assertions.fail("Expected ResponseStatusException");
        } catch (ResponseStatusException exception) {
            assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
            assertThat(exception.getReason()).isEqualTo("Конфигурация не найдена");
        }
    }
}


