package com.femsq.web.api.graphql;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.web.config.IntegrationTestConfiguration;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
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
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.Objects;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * Интеграционный тест для GraphQL контроллера организаций.
 * 
 * Использует @DirtiesContext для полной изоляции Spring контекста после выполнения тестов.
 * Добавлена задержка и ретраи для ожидания готовности GraphQL endpoint.
 * 
 * ВАЖНО: Этот тест должен выполняться ПЕРВЫМ среди всех интеграционных тестов модуля.
 * Имя класса начинается с "Og" чтобы быть раньше "Api" в алфавитном порядке.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@SpringBootTest(classes = IntegrationTestConfiguration.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@org.springframework.test.annotation.DirtiesContext(classMode = org.springframework.test.annotation.DirtiesContext.ClassMode.AFTER_CLASS)
class OgGraphqlControllerIT {

    private static final Logger log = Logger.getLogger(OgGraphqlControllerIT.class.getName());
    private static final Path SEED_SCRIPT = Path.of("..", "..", "config", "sql", "ags_test_seed.sql");

    @Autowired
    private org.springframework.boot.test.web.client.TestRestTemplate restTemplate;

    private static String originalUserHome;
    private static Path temporaryHome;
    private static DatabaseConfigurationProperties configuration;

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        try {
            if (originalUserHome == null) {
                String realUserHome = System.getenv("HOME");
                if (realUserHome == null || realUserHome.isBlank()) {
                    realUserHome = System.getProperty("user.home");
                }
                originalUserHome = realUserHome;
            }
            temporaryHome = Files.createTempDirectory("femsq-home-it-graphql");
            System.setProperty("user.home", temporaryHome.toString());
            registry.add("user.home", () -> temporaryHome.toString());
        } catch (IOException exception) {
            throw new RuntimeException("Не удалось создать временную директорию для теста", exception);
        }
    }

    @BeforeAll
    void setUp() throws Exception {
        assumeTrue(isDatabaseConfigured(), "Переменные окружения FEMSQ_DB_* не заданы, тест пропущен");

        if (temporaryHome == null) {
            temporaryHome = Files.createTempDirectory("femsq-home-it-graphql");
            System.setProperty("user.home", temporaryHome.toString());
        }

        configuration = configurationFromEnv();
        writeConfiguration(configuration);
        seedDatabase();
    }

    @AfterAll
    static void tearDown() throws IOException {
        if (temporaryHome != null) {
            try {
                Files.walk(temporaryHome)
                        .sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            try {
                                Files.deleteIfExists(path);
                            } catch (IOException ignored) {
                            }
                        });
            } catch (Exception ignored) {
            }
        }
        if (originalUserHome != null) {
            System.setProperty("user.home", originalUserHome);
        }
    }

    @BeforeEach
    void resetSchema() throws Exception {
        seedDatabase();
    }

    @Test
    @Order(1)
    void shouldReturnOrganizationsViaGraphQl() throws InterruptedException {
        log.info("Выполняем GraphQL запрос organizations через HTTP");
        
        // Ожидание инициализации GraphQL endpoint
        log.info("Ожидание 2 секунды для инициализации GraphQL endpoint");
        Thread.sleep(2000);
        
        // Проверка готовности GraphQL endpoint с ретраями
        HttpHeaders testHeaders = new HttpHeaders();
        testHeaders.setContentType(MediaType.APPLICATION_JSON);
        Map<String, String> testPayload = Map.of("query", "{ __typename }");
        HttpEntity<Map<String, String>> testRequest = new HttpEntity<>(testPayload, testHeaders);
        
        boolean endpointReady = false;
        for (int i = 1; i <= 10; i++) {
            try {
                ResponseEntity<Map<String, Object>> testResponse = restTemplate.exchange(
                        "/graphql",
                        HttpMethod.POST,
                        testRequest,
                        new ParameterizedTypeReference<>() {
                        });
                int status = testResponse.getStatusCode().value();
                log.info(String.format("Попытка %d/10: GraphQL endpoint вернул статус %d", i, status));
                if (status == 200) {
                    log.info("GraphQL endpoint готов!");
                    endpointReady = true;
                    break;
                }
            } catch (Exception e) {
                log.warning(String.format("Попытка %d/10: Ошибка проверки endpoint: %s", i, e.getMessage()));
            }
            Thread.sleep(1000);
        }
        
        if (!endpointReady) {
            log.severe("GraphQL endpoint не стал доступен после 10 попыток!");
            org.junit.jupiter.api.Assertions.fail("GraphQL endpoint не доступен после всех попыток");
        }

        // Основной запрос
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

        log.info("GraphQL response status: " + response.getStatusCode().value());
        if (!response.getStatusCode().is2xxSuccessful()) {
            log.warning("GraphQL response body: " + response.getBody());
        }
        
        assertThat(response.getStatusCode().is2xxSuccessful())
                .as("GraphQL запрос должен вернуть успешный статус, получен: " + response.getStatusCode())
                .isTrue();
        Map<String, Object> body = Objects.requireNonNull(response.getBody());
        
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        assertThat(data).isNotNull();
        
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> organizations = (List<Map<String, Object>>) data.get("organizations");
        assertThat(organizations)
                .hasSize(3)
                .extracting(entry -> entry.get("ogName"))
                .containsExactly("Рога, ООО", "Рога и копыта, АО", "Копыта и хвосты, ИП");
    }

    private boolean isDatabaseConfigured() {
        return System.getenv("FEMSQ_DB_HOST") != null &&
                System.getenv("FEMSQ_DB_PORT") != null &&
                System.getenv("FEMSQ_DB_NAME") != null &&
                System.getenv("FEMSQ_DB_SCHEMA") != null &&
                System.getenv("FEMSQ_DB_USER") != null &&
                System.getenv("FEMSQ_DB_PASSWORD") != null &&
                System.getenv("FEMSQ_DB_AUTH_MODE") != null;
    }

    private DatabaseConfigurationProperties configurationFromEnv() {
        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "Fish_Eye");
        String schema = envOr("FEMSQ_DB_SCHEMA", "ags_test");
        String username = envOr("FEMSQ_DB_USER", "sa");
        String authMode = envOr("FEMSQ_DB_AUTH_MODE", "credentials").toLowerCase(Locale.ROOT);
        String password = "credentials".equals(authMode) ? System.getenv("FEMSQ_DB_PASSWORD") : null;
        return new DatabaseConfigurationProperties(host, port, database, schema, username, password, authMode, null);
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
