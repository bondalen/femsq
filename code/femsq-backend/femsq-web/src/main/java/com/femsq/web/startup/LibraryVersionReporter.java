package com.femsq.web.startup;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Генератор файла отчёта о версиях библиотек.
 * Создаёт файл versions_YY-MMDD-hhmm.txt с детальной информацией о проверке библиотек.
 */
public class LibraryVersionReporter {
    
    private static final Logger log = LoggerFactory.getLogger(LibraryVersionReporter.class);
    private static final String MANIFEST_PATH = "META-INF/lib-manifest.json";
    private static final DateTimeFormatter REPORT_TIMESTAMP_FORMATTER = 
        DateTimeFormatter.ofPattern("yy-MMdd-HHmm");
    
    /**
     * Генерирует файл отчёта о версиях библиотек.
     * 
     * @param libDir путь к директории lib/
     * @param reportDir директория для сохранения отчёта (обычно рядом с тонким JAR)
     * @return путь к созданному файлу отчёта
     */
    public static Path generateReport(Path libDir, Path reportDir) {
        try {
            // Создаём директорию для отчёта, если не существует
            if (!Files.exists(reportDir)) {
                Files.createDirectories(reportDir);
            }
            
            // Генерируем имя файла с временной меткой
            String timestamp = LocalDateTime.now().format(REPORT_TIMESTAMP_FORMATTER);
            String reportFileName = "versions_" + timestamp + ".txt";
            Path reportPath = reportDir.resolve(reportFileName);
            
            // Читаем lib-manifest.json
            InputStream manifestStream = LibraryVersionReporter.class
                .getClassLoader()
                .getResourceAsStream(MANIFEST_PATH);
            
            if (manifestStream == null) {
                log.warn("lib-manifest.json not found, cannot generate version report");
                return null;
            }
            
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(manifestStream);
            
            // Генерируем отчёт
            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(reportPath))) {
                writeReport(writer, root, libDir);
            }
            
            log.info("Library version report generated: {}", reportPath);
            return reportPath;
            
        } catch (Exception e) {
            log.error("Failed to generate library version report", e);
            return null;
        }
    }
    
    private static void writeReport(PrintWriter writer, JsonNode root, Path libDir) throws IOException {
        JsonNode buildInfo = root.get("buildInfo");
        JsonNode libraries = root.get("libraries");
        
        // Заголовок
        writer.println("========================================");
        writer.println("FEMSQ: Library Version Report");
        writer.println("========================================");
        writer.println("Date: " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        
        if (buildInfo != null) {
            String appVersion = buildInfo.has("appVersion") ? buildInfo.get("appVersion").asText() : "unknown";
            writer.println("Thin JAR version: " + appVersion);
            writer.println("Expected version: " + appVersion);
        }
        
        writer.println("========================================");
        writer.println();
        
        // Информация о сборке
        if (buildInfo != null) {
            writer.println("BUILD INFO:");
            writer.println("  App Version: " + (buildInfo.has("appVersion") ? buildInfo.get("appVersion").asText() : "unknown"));
            writer.println("  Build Number: " + (buildInfo.has("buildNumber") ? buildInfo.get("buildNumber").asText() : "unknown"));
            writer.println("  Build Timestamp: " + (buildInfo.has("buildTimestamp") ? buildInfo.get("buildTimestamp").asText() : "unknown"));
            writer.println();
        }
        
        if (libraries == null || !libraries.isArray()) {
            writer.println("ERROR: No libraries found in lib-manifest.json");
            return;
        }
        
        // Статистика
        int total = libraries.size();
        int checked = 0;
        int ok = 0;
        int warnings = 0;
        int errors = 0;
        int optionalMissing = 0; // Счётчик для optional libraries (не считается как warning)
        
        List<LibraryCheckResult> results = new ArrayList<>();
        
        // Проверяем каждую библиотеку
        for (JsonNode libNode : libraries) {
            checked++;
            String filename = libNode.get("filename").asText();
            boolean required = libNode.has("required") && libNode.get("required").asBoolean();
            String expectedVersion = libNode.has("version") ? libNode.get("version").asText() : null;
            
            Path libFile = libDir.resolve(filename);
            LibraryCheckResult result = new LibraryCheckResult();
            result.filename = filename;
            result.required = required;
            result.expectedVersion = expectedVersion;
            
            if (!Files.exists(libFile)) {
                if (required) {
                    errors++;
                    result.status = "MISSING";
                    result.action = "ADD REQUIRED";
                } else {
                    // Optional libraries не считаются как warnings, но остаются в отчёте
                    optionalMissing++;
                    result.status = "MISSING (optional)";
                    result.action = "OK (optional)";
                }
            } else {
                // Проверяем версию для femsq-* библиотек
                if (filename.startsWith("femsq-") && expectedVersion != null) {
                    String actualVersion = extractVersionFromFilename(filename);
                    JsonNode compatibleVersions = libNode.get("compatibleVersions");
                    
                    boolean isCompatible = false;
                    if (compatibleVersions != null && compatibleVersions.isArray()) {
                        for (JsonNode compatVersion : compatibleVersions) {
                            if (compatVersion.asText().equals(actualVersion)) {
                                isCompatible = true;
                                break;
                            }
                        }
                    }
                    
                    if (expectedVersion.equals(actualVersion)) {
                        ok++;
                        result.status = "MATCH";
                        result.action = "OK";
                    } else if (isCompatible) {
                        ok++;
                        result.status = "COMPATIBLE VERSION";
                        result.action = "OK (no update needed)";
                        result.compatibleVersions = getCompatibleVersionsList(compatibleVersions);
                    } else {
                        errors++;
                        result.status = "VERSION MISMATCH";
                        result.action = "UPDATE REQUIRED";
                        result.compatibleVersions = getCompatibleVersionsList(compatibleVersions);
                    }
                    result.actualVersion = actualVersion;
                } else {
                    // Для внешних библиотек - только проверка наличия файла с правильным именем
                    ok++;
                    result.status = "MATCH";
                    result.action = "OK";
                }
            }
            
            results.add(result);
        }
        
        // Выводим статистику
        writer.println("LIBRARY CHECK RESULTS:");
        writer.println("  Total libraries: " + total);
        writer.println("  Checked: " + checked);
        writer.println("  OK: " + ok);
        writer.println("  Optional missing: " + optionalMissing + " (not counted as warnings)");
        writer.println("  WARNING: " + warnings);
        writer.println("  ERROR: " + errors);
        writer.println();
        
        // Детальные результаты
        writer.println("DETAILED RESULTS:");
        writer.println();
        
        for (LibraryCheckResult result : results) {
            // Пропускаем успешные обязательные библиотеки для краткости
            // Показываем все остальные: ошибки, предупреждения, optional missing, совместимые версии
            if ("MATCH".equals(result.status) && result.required) {
                continue;
            }
            
            // Определяем статус для отображения
            String displayStatus;
            if (result.status.startsWith("ERROR") || "MISSING".equals(result.status)) {
                displayStatus = "ERROR";
            } else if (result.status.contains("WARNING") || result.status.contains("MISMATCH")) {
                displayStatus = "WARNING";
            } else if (result.status.contains("optional")) {
                displayStatus = "INFO"; // Optional libraries показываем как INFO, не WARNING
            } else {
                displayStatus = "OK";
            }
            
            writer.println("[" + displayStatus + "] " + result.filename);
            
            if (result.expectedVersion != null) {
                writer.println("  Expected: " + result.expectedVersion);
            }
            
            if (result.compatibleVersions != null && !result.compatibleVersions.isEmpty()) {
                writer.println("  Compatible versions: " + String.join(", ", result.compatibleVersions));
            }
            
            if (result.actualVersion != null) {
                writer.println("  Found: " + result.actualVersion);
            } else if (result.status.contains("MISSING")) {
                writer.println("  Found: NOT FOUND");
            }
            
            writer.println("  Status: " + result.status);
            writer.println("  Action: " + result.action);
            writer.println();
        }
        
        // Итог
        writer.println("========================================");
        writer.println("SUMMARY");
        writer.println("========================================");
        
        if (errors > 0) {
            writer.println("Application startup: BLOCKED");
            writer.println("Reason: Critical library version mismatches detected");
            writer.println("Errors: " + errors);
            writer.println("Warnings: " + warnings);
            writer.println();
            writer.println("Required actions:");
            int actionNum = 1;
            for (LibraryCheckResult result : results) {
                if (result.status.contains("ERROR") || "MISSING".equals(result.status)) {
                    if ("UPDATE REQUIRED".equals(result.action)) {
                        writer.println("  " + actionNum + ". Update " + result.filename + 
                            " to version " + result.expectedVersion);
                    } else if ("ADD REQUIRED".equals(result.action)) {
                        writer.println("  " + actionNum + ". Add " + result.filename + " to lib/ directory");
                    }
                    actionNum++;
                }
            }
        } else if (warnings > 0) {
            writer.println("Application startup: ALLOWED");
            writer.println("Reason: Non-critical warnings detected");
            writer.println("Warnings: " + warnings);
        } else {
            writer.println("Application startup: ALLOWED");
            writer.println("Reason: All libraries are compatible");
        }
    }
    
    private static String extractVersionFromFilename(String filename) {
        String nameWithoutExt = filename.replace(".jar", "");
        String[] parts = nameWithoutExt.split("-");
        if (parts.length >= 2) {
            return String.join("-", Arrays.copyOfRange(parts, parts.length - 2, parts.length));
        }
        return "unknown";
    }
    
    private static List<String> getCompatibleVersionsList(JsonNode compatibleVersions) {
        List<String> list = new ArrayList<>();
        if (compatibleVersions != null && compatibleVersions.isArray()) {
            for (JsonNode version : compatibleVersions) {
                list.add(version.asText());
            }
        }
        return list;
    }
    
    private static class LibraryCheckResult {
        String filename;
        boolean required;
        String expectedVersion;
        String actualVersion;
        String status;
        String action;
        List<String> compatibleVersions;
    }
}
