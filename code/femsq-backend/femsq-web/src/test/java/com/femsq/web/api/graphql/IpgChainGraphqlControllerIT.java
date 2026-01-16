package com.femsq.web.api.graphql;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.femsq.database.config.DatabaseConfigurationService.DatabaseConfigurationProperties;
import com.femsq.web.config.IntegrationTestConfiguration;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
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
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@SpringBootTest(classes = IntegrationTestConfiguration.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@org.springframework.test.annotation.DirtiesContext(classMode = org.springframework.test.annotation.DirtiesContext.ClassMode.AFTER_CLASS)
class IpgChainGraphqlControllerIT {

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
            temporaryHome = Files.createTempDirectory("femsq-home-it-graphql-ipg");
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
            temporaryHome = Files.createTempDirectory("femsq-home-it-graphql-ipg");
            System.setProperty("user.home", temporaryHome.toString());
        }
        configuration = configurationFromEnv();
        writeConfiguration(configuration);
    }

    @AfterAll
    static void tearDown() throws Exception {
        if (temporaryHome != null && Files.exists(temporaryHome)) {
            Files.walk(temporaryHome)
                    .sorted((a, b) -> -a.compareTo(b))
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException ignored) {
                        }
                    });
        }
        if (originalUserHome != null) {
            System.setProperty("user.home", originalUserHome);
        }
    }

    @BeforeEach
    void waitForGraphql() throws InterruptedException {
        Thread.sleep(500);
    }

    @Test
    @Order(1)
    void stNetworksQueryReturnsData() throws InterruptedException {
        Thread.sleep(1000);
        String query = "{ stNetworks { stNetKey name } }";
        Map<String, Object> response = executeGraphQlQuery(query);
        assertThat(response).containsKey("data");
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) response.get("data");
        assertThat(data).containsKey("stNetworks");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> networks = (List<Map<String, Object>>) data.get("stNetworks");
        assertThat(networks).isNotNull();
    }

    @Test
    @Order(2)
    void investmentProgramsQueryReturnsData() throws InterruptedException {
        Thread.sleep(1000);
        String query = "{ investmentPrograms { ipgKey name } }";
        Map<String, Object> response = executeGraphQlQuery(query);
        assertThat(response).containsKey("data");
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) response.get("data");
        assertThat(data).containsKey("investmentPrograms");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> programs = (List<Map<String, Object>>) data.get("investmentPrograms");
        assertThat(programs).isNotNull();
    }

    @Test
    @Order(3)
    void investmentPlanGroupsQueryReturnsData() throws InterruptedException {
        Thread.sleep(1000);
        String query = "{ investmentPlanGroups { planGroupKey name } }";
        Map<String, Object> response = executeGraphQlQuery(query);
        assertThat(response).containsKey("data");
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) response.get("data");
        assertThat(data).containsKey("investmentPlanGroups");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> groups = (List<Map<String, Object>>) data.get("investmentPlanGroups");
        assertThat(groups).isNotNull();
    }

    @Test
    @Order(4)
    void investmentChainsQueryReturnsData() throws InterruptedException {
        Thread.sleep(1000);
        String query = "{ investmentChains { chainKey name stNetKey stNetName year } }";
        Map<String, Object> response = executeGraphQlQuery(query);
        assertThat(response).containsKey("data");
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) response.get("data");
        assertThat(data).containsKey("investmentChains");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> chains = (List<Map<String, Object>>) data.get("investmentChains");
        assertThat(chains).isNotNull();
    }

    private Map<String, Object> executeGraphQlQuery(String query) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        Map<String, String> requestBody = Map.of("query", query);
        HttpEntity<Map<String, String>> request = new HttpEntity<>(requestBody, headers);
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                "/graphql",
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {
                });
        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        return response.getBody();
    }

    private static boolean isDatabaseConfigured() {
        String password = System.getenv("FEMSQ_DB_PASSWORD");
        return password != null && !password.isBlank();
    }

    private static DatabaseConfigurationProperties configurationFromEnv() {
        String host = envOr("FEMSQ_DB_HOST", "localhost");
        int port = Integer.parseInt(envOr("FEMSQ_DB_PORT", "1433"));
        String database = envOr("FEMSQ_DB_NAME", "FishEye");
        String schema = envOr("FEMSQ_DB_SCHEMA", "ags_test");
        String authMode = envOr("FEMSQ_DB_AUTH_MODE", "credentials").toLowerCase();
        String username = "credentials".equals(authMode) ? envOr("FEMSQ_DB_USER", "sa") : null;
        String password = "credentials".equals(authMode) ? System.getenv("FEMSQ_DB_PASSWORD") : null;
        return new DatabaseConfigurationProperties(host, port, database, schema, username, password, authMode, null);
    }

    private static void writeConfiguration(DatabaseConfigurationProperties config) throws IOException {
        Path configDir = temporaryHome.resolve(".femsq");
        Files.createDirectories(configDir);
        Path configFile = configDir.resolve("db-config.json");
        String json = String.format(
                "{\"host\":\"%s\",\"port\":%d,\"database\":\"%s\",\"schema\":\"%s\",\"username\":\"%s\",\"password\":\"%s\",\"authMode\":\"%s\"}",
                config.host(), config.port(), config.database(), config.schema(),
                config.username() != null ? config.username() : "",
                config.password() != null ? config.password() : "",
                config.authMode());
        Files.writeString(configFile, json);
    }

    private static String envOr(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }
}
