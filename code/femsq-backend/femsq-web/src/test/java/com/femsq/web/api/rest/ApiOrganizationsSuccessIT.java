package com.femsq.web.api.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.junit.jupiter.api.Assertions.fail;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.dto.PageResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Logger;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

/**
 * Интеграционный тест, демонстрирующий работу REST API с реальной схемой {@code ags_test}.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApiOrganizationsSuccessIT {

    private static final Logger log = Logger.getLogger(ApiOrganizationsSuccessIT.class.getName());
    private static final Duration MANUAL_TIMEOUT = Duration.ofMinutes(3);
    private static final String MANUAL_FLAG = "femsq.api.manual";
    private static final Path SEED_SCRIPT = Path.of("..", "..", "config", "sql", "ags_test_seed.sql");

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int localPort;

    private String originalUserHome;
    private Path temporaryHome;
    private DatabaseConfigurationProperties configuration;

    @BeforeAll
    void setUpUserHomeAndConfiguration() throws Exception {
        assumeTrue(isDatabaseConfigured(), "Переменные окружения FEMSQ_DB_* не заданы, тест пропущен");

        configuration = configurationFromEnv();

        originalUserHome = System.getProperty("user.home");
        temporaryHome = Files.createTempDirectory("femsq-home-it-success");
        System.setProperty("user.home", temporaryHome.toString());

        writeConfiguration(configuration);
        seedDatabase();
    }

    @AfterAll
    void restoreUserHome() throws IOException {
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
                            // Игнорируем ошибки удаления временных файлов.
                        }
                    });
        }
    }

    @BeforeEach
    void resetSchema() throws Exception {
        seedDatabase();
    }

    @Test
    @Order(1)
    void shouldReturnOrganizationsFromAgsTestSchema() {
        ResponseEntity<PageResponse<OgDto>> response = restTemplate.exchange(
                "/api/v1/organizations",
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<>() {
                });

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        PageResponse<OgDto> pageResponse = Objects.requireNonNull(response.getBody());
        assertThat(pageResponse.content())
                .extracting(OgDto::ogName)
                .containsExactly(
                        "Рога, ООО",
                        "Рога и копыта, АО",
                        "Копыта и хвосты, ИП");
    }

    @Test
    @Order(2)
    void shouldReturnAgentsFromAgsTestSchema() {
        ResponseEntity<List<OgAgDto>> response = restTemplate.exchange(
                "/api/v1/agents",
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<>() {
                });

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody())
                .isNotNull()
                .extracting(OgAgDto::code)
                .containsExactly("001", "002", "003");
        assertThat(response.getBody())
                .extracting(OgAgDto::organizationKey)
                .containsExactly(1, 2, 3);
    }

    @Test
    @org.junit.jupiter.api.Disabled("GraphQL endpoint не регистрируется в тестовом контексте - требуется дополнительная настройка Spring GraphQL")
    @Order(3)
    void shouldReturnOrganizationsViaGraphQl() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        Map<String, String> payload = Map.of("query", "{ organizations { ogKey ogName } }");
        HttpEntity<Map<String, String>> request = new HttpEntity<>(payload, headers);

        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                "/graphql",
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<>() {
                });

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        Map<String, Object> body = Objects.requireNonNull(response.getBody());
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        assertThat(data).isNotNull();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> organizations = (List<Map<String, Object>>) data.get("organizations");
        assertThat(organizations)
                .extracting(entry -> entry.get("ogName"))
                .containsExactly("Рога, ООО", "Рога и копыта, АО", "Копыта и хвосты, ИП");
    }

    @Test
    @Order(100)
    void manualVerificationIfRequested() {
        if (!Boolean.getBoolean(MANUAL_FLAG)) {
            return;
        }

        long timeoutMillis = Long.getLong("femsq.api.manual.timeoutMillis", MANUAL_TIMEOUT.toMillis());
        String stopFilePath = System.getProperty("femsq.api.manual.stopFile");
        Path stopFile = stopFilePath != null ? Path.of(stopFilePath) : null;

        if (stopFile != null) {
            log.info(() -> "Ручной режим включен. Сервер запущен на http://localhost:" + localPort
                    + ". Выполните запросы к REST/GraphQL API (данные загружены из схемы ags_test)."
                    + " Для досрочного завершения создайте файл " + stopFile + "."
                    + " Таймаут ожидания — " + timeoutMillis / 1000 + " сек.");
        } else {
            log.info(() -> "Ручной режим включен. Сервер запущен на http://localhost:" + localPort
                    + ". Выполните запросы к REST/GraphQL API (данные загружены из схемы ags_test)."
                    + " Сервер останется доступен примерно " + timeoutMillis / 1000 + " сек.");
        }

        long deadline = System.currentTimeMillis() + timeoutMillis;
        try {
            while (System.currentTimeMillis() < deadline) {
                if (stopFile != null && Files.exists(stopFile)) {
                    log.info(() -> "Обнаружен файл завершения " + stopFile + ". Сервер останавливается.");
                    Files.deleteIfExists(stopFile);
                    return;
                }
                Thread.sleep(1000);
            }
        } catch (InterruptedException interruptedException) {
            Thread.currentThread().interrupt();
            fail("Ожидание ручной проверки было прервано");
        } catch (IOException ioException) {
            log.warning("Не удалось удалить файл завершения: " + ioException.getMessage());
        }

        log.info("Таймаут ожидания истёк, сервер будет остановлен автоматически");
    }

    private boolean isDatabaseConfigured() {
        String password = System.getenv("FEMSQ_DB_PASSWORD");
        return password != null && !password.isBlank();
    }

    private DatabaseConfigurationProperties configurationFromEnv() {
        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "Fish_Eye");
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

    private void seedDatabase() throws IOException, SQLException {
        DatabaseConfigurationProperties config = configurationFromEnv();
        List<String> lines = Files.readAllLines(SEED_SCRIPT, StandardCharsets.UTF_8);
        // Заменяем жестко прописанное имя базы данных на реальное из конфигурации
        List<String> processedLines = lines.stream()
                .map(line -> line.replaceAll("\\[FishEye\\]", "[" + config.database() + "]")
                        .replaceAll("FishEye\\.", config.database() + "."))
                .toList();
        DatabaseConfigurationService configurationService = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (com.femsq.database.connection.ConnectionFactory factory = new com.femsq.database.connection.ConnectionFactory(configurationService);
             Connection connection = factory.createConnection()) {
            executeScript(connection, processedLines);
        }
    }

    private void executeScript(Connection connection, List<String> lines) throws SQLException {
        StringBuilder statementBuilder = new StringBuilder();
        try (Statement statement = connection.createStatement()) {
            for (String line : lines) {
                if (line.trim().equalsIgnoreCase("GO")) {
                    runStatement(statement, statementBuilder);
                } else {
                    statementBuilder.append(line).append(System.lineSeparator());
                }
            }
            runStatement(statement, statementBuilder);
        }
    }

    private void runStatement(Statement statement, StringBuilder statementBuilder) throws SQLException {
        String sql = statementBuilder.toString().trim();
        if (!sql.isEmpty()) {
            statement.execute(sql);
        }
        statementBuilder.setLength(0);
    }

    private String envOr(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }
}
