package com.femsq.web.api.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.fail;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Comparator;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;

/**
 * Интеграционный тест, фиксирующий ожидаемое поведение API при отсутствии конфигурации БД.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApiMissingConfigurationIT {

    private static final Logger log = Logger.getLogger(ApiMissingConfigurationIT.class.getName());
    private static final Duration MANUAL_TIMEOUT = Duration.ofMinutes(3);
    private static final String MANUAL_FLAG = "femsq.api.manual";

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int localPort;

    private String originalUserHome;
    private Path temporaryHome;
    @BeforeAll
    void setUpUserHome() throws IOException {
        originalUserHome = System.getProperty("user.home");
        temporaryHome = Files.createTempDirectory("femsq-home-it");
        System.setProperty("user.home", temporaryHome.toString());
        log.info(() -> "Тест выполняется в изолированном каталоге " + temporaryHome);
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

    @Test
    @Order(1)
    void shouldReturnServiceUnavailableWhenConfigurationMissing() {
        ResponseEntity<String> response = restTemplate.getForEntity("/api/v1/organizations", String.class);

        assertThat(response.getStatusCode().value()).isEqualTo(503);
        assertThat(response.getBody())
                .as("Ответ должен содержать сообщение о недоступной конфигурации")
                .contains("Файл конфигурации подключения к базе данных не найден");
    }

    @Test
    @Order(100)
    void manualVerificationIfRequested() {
        if (!Boolean.getBoolean(MANUAL_FLAG)) {
            return;
        }

        log.info(() -> "Ручной режим включен. Сервер запущен на http://localhost:" + localPort
                + ". Выполните необходимые проверки REST/GraphQL API и нажмите Enter для продолжения."
                + " Таймаут ожидания — " + MANUAL_TIMEOUT.toMinutes() + " минут(ы).");

        CountDownLatch latch = new CountDownLatch(1);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.submit(() -> {
            try {
                int read = System.in.read();
                log.fine(() -> "Получен ввод пользователя: " + read);
            } catch (IOException exception) {
                log.warning("Ошибка чтения пользовательского ввода: " + exception.getMessage());
            } finally {
                latch.countDown();
            }
        });

        boolean completed;
        try {
            completed = latch.await(MANUAL_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
        } catch (InterruptedException interruptedException) {
            Thread.currentThread().interrupt();
            executor.shutdownNow();
            fail("Ожидание пользовательского ввода было прервано");
            return;
        }

        executor.shutdownNow();

        if (!completed) {
            fail("Ручной сценарий не завершён за " + MANUAL_TIMEOUT.toMinutes() + " минут(ы)");
        }

        log.info("Ручная проверка завершена, тест продолжает выполнение");
    }
}
