package com.femsq.web.logging;

import com.femsq.database.util.JarPathResolver;
import com.femsq.web.api.dto.ConnectionTestRequest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.stereotype.Component;

/**
 * Сервис аудита попыток подключения к БД.
 * <p>
 * Записывает каждую попытку в лог-файл, чтобы заказчик мог анализировать причины
 * неудачных подключений без доступа к консоли браузера.
 * Путь до каталога можно переопределить системным свойством {@code femsq.audit.dir}
 * или переменной окружения {@code FEMSQ_AUDIT_DIR}.
 */
@Component
public class ConnectionAttemptLogger {

    private static final Logger log = Logger.getLogger(ConnectionAttemptLogger.class.getName());
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ISO_OFFSET_DATE_TIME;
    private static final String DEFAULT_FILE_NAME = "connection-attempts.log";
    private final Path logFilePath;

    public ConnectionAttemptLogger() {
        this(resolveLogFilePath());
    }

    ConnectionAttemptLogger(Path logFilePath) {
        this.logFilePath = Objects.requireNonNull(logFilePath, "logFilePath");
    }

    /**
     * Записывает попытку подключения в лог.
     *
     * @param request исходные данные подключения (без пароля)
     * @param success {@code true}, если подключение установлено
     * @param message человеко-читаемое сообщение о результате
     * @param error   причина сбоя (опционально)
     */
    public void logAttempt(ConnectionTestRequest request, boolean success, String message, Throwable error) {
        Objects.requireNonNull(request, "request");
        String entry = buildEntry(request, success, message, error);
        writeEntry(entry);
    }
    private String buildEntry(ConnectionTestRequest request, boolean success, String message, Throwable error) {
        StringBuilder builder = new StringBuilder();
        builder.append("timestamp=")
                .append(FORMATTER.format(ZonedDateTime.now()))
                .append(" | result=")
                .append(success ? "SUCCESS" : "FAILURE")
                .append(" | host=")
                .append(request.host())
                .append(" | port=")
                .append(request.port())
                .append(" | database=")
                .append(request.database())
                .append(" | schema=")
                .append(Optional.ofNullable(request.schema()).orElse("<none>"))
                .append(" | authMode=")
                .append(request.authMode())
                .append(" | username=")
                .append(safeValue(request.username()))
                .append(" | message=")
                .append(sanitize(message));

        if (error != null) {
            builder.append(" | error=")
                    .append(sanitize(error.getClass().getSimpleName()))
                    .append(": ")
                    .append(sanitize(error.getMessage()));
        }
        return builder.append(System.lineSeparator()).toString();
    }

    private void writeEntry(String entry) {
        Path parent = logFilePath.getParent();
        try {
            if (parent != null) {
                Files.createDirectories(parent);
            }
            Files.writeString(logFilePath, entry, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException exception) {
            log.log(Level.WARNING, "Failed to write connection attempt log", exception);
        }
    }
    private static String safeValue(String value) {
        return value == null || value.isBlank() ? "<none>" : value;
    }

    private static String sanitize(String input) {
        if (input == null || input.isBlank()) {
            return "-";
        }
        return input.replaceAll("[\r\n]+", " ").trim();
    }

    private static Path resolveLogFilePath() {
        String override = System.getProperty("femsq.audit.dir");
        if (override == null || override.isBlank()) {
            override = System.getenv("FEMSQ_AUDIT_DIR");
        }

        Path directory;
        if (override != null && !override.isBlank()) {
            directory = Paths.get(override);
        } else {
            // Пытаемся найти каталог рядом с JAR
            try {
                // Используем утилиту для определения каталога JAR
                // Пробуем сначала класс из основного модуля (web)
                Path jarDir;
                try {
                    Class<?> mainClass = Class.forName("com.femsq.web.FemsqWebApplication");
                    jarDir = JarPathResolver.resolveJarDirectory(mainClass);
                } catch (ClassNotFoundException e) {
                    // Если основной класс недоступен, используем текущий класс
                    jarDir = JarPathResolver.resolveJarDirectory(ConnectionAttemptLogger.class);
                }
                
                directory = jarDir.resolve("logs");
            } catch (Exception exception) {
                log.log(Level.WARNING, "Could not determine JAR directory, using user.dir", exception);
                directory = Paths.get(System.getProperty("user.dir"), "logs");
            }
        }

        if (!Files.isDirectory(directory)) {
            try {
                Files.createDirectories(directory);
                log.log(Level.INFO, "Created audit log directory: {0}", directory);
            } catch (IOException exception) {
                log.log(Level.WARNING, "Failed to create audit directory, falling back to temp", exception);
                directory = Paths.get(System.getProperty("java.io.tmpdir"));
            }
        }

        Path logFile = directory.resolve(DEFAULT_FILE_NAME);
        log.log(Level.INFO, "Connection attempt log file: {0}", logFile);
        return logFile;
    }
}
