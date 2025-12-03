package com.femsq.web.startup;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.*;

/**
 * Проверяет совместимость внешних библиотек при запуске thin JAR.
 * Читает META-INF/lib-manifest.json и сравнивает с библиотеками в lib/.
 * Блокирует запуск при критических несоответствиях версий.
 */
public class LibraryCompatibilityChecker {
    
    private static final Logger log = LoggerFactory.getLogger(LibraryCompatibilityChecker.class);
    private static final String MANIFEST_PATH = "META-INF/lib-manifest.json";
    
    /**
     * Проверяет совместимость библиотек.
     * 
     * @param libDir путь к директории lib/
     * @param reportDir директория для сохранения отчёта (обычно рядом с тонким JAR)
     * @return результат проверки
     */
    public static ValidationResult verify(Path libDir, Path reportDir) {
        ValidationResult result = new ValidationResult();
        
        try {
            // Читаем lib-manifest.json из classpath
            InputStream manifestStream = LibraryCompatibilityChecker.class
                .getClassLoader()
                .getResourceAsStream(MANIFEST_PATH);
            
            if (manifestStream == null) {
                log.warn("lib-manifest.json not found in JAR. Skipping library validation.");
                result.addWarning("lib-manifest.json not found - cannot validate libraries");
                return result;
            }
            
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(manifestStream);
            
            JsonNode buildInfo = root.get("buildInfo");
            if (buildInfo != null) {
                String appVersion = buildInfo.get("appVersion").asText();
                String buildNumber = buildInfo.get("buildNumber").asText();
                log.info("Validating libraries for app version: {} (build: {})", appVersion, buildNumber);
            }
            
            JsonNode libraries = root.get("libraries");
            if (libraries == null || !libraries.isArray()) {
                log.warn("No libraries found in lib-manifest.json");
                return result;
            }
            
            // Проверяем каждую библиотеку
            for (JsonNode libNode : libraries) {
                String filename = libNode.get("filename").asText();
                boolean required = libNode.has("required") && libNode.get("required").asBoolean();
                String expectedVersion = libNode.has("version") ? libNode.get("version").asText() : null;
                
                Path libFile = libDir.resolve(filename);
                
                if (!Files.exists(libFile)) {
                    if (required) {
                        result.addError("Required library missing: " + filename);
                        log.error("Required library missing: {}", filename);
                    } else {
                        // Optional libraries не добавляем в warnings и логируем на уровне debug
                        log.debug("Optional library missing: {} (not required, skipping)", filename);
                    }
                    continue;
                }
                
                // Для femsq-* библиотек проверяем версию с учётом compatibleVersions
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
                    
                    if (!expectedVersion.equals(actualVersion) && !isCompatible) {
                        // Версия не совпадает и не в списке совместимых - критическая ошибка
                        result.addError(String.format(
                            "Version mismatch for %s: expected %s (or compatible), found %s",
                            filename, expectedVersion, actualVersion
                        ));
                        log.error("Version mismatch for {}: expected {} (or compatible), found {}",
                            filename, expectedVersion, actualVersion);
                    } else if (isCompatible && !expectedVersion.equals(actualVersion)) {
                        // Используется совместимая версия - предупреждение
                        result.addWarning(String.format(
                            "Using compatible version for %s: expected %s, found %s (compatible)",
                            filename, expectedVersion, actualVersion
                        ));
                        log.warn("Using compatible version for {}: expected {}, found {} (compatible)",
                            filename, expectedVersion, actualVersion);
                    }
                }
                
                // Для внешних библиотек - только проверка точного совпадения имени файла
                if (!filename.startsWith("femsq-")) {
                    // Файл существует с правильным именем - OK
                    log.debug("External library found: {}", filename);
                }
            }
            
            // Проверяем наличие native-libs (если требуется Windows Auth)
            if (System.getProperty("femsq.windows.auth", "false").equals("true")) {
                Path nativeLibsDir = libDir.getParent().resolve("native-libs");
                if (!Files.exists(nativeLibsDir)) {
                    result.addWarning("native-libs directory not found (required for Windows Authentication)");
                    log.warn("native-libs directory not found");
                }
            }
            
            // Генерируем файл отчёта
            if (reportDir != null) {
                Path reportPath = LibraryVersionReporter.generateReport(libDir, reportDir);
                if (reportPath != null) {
                    log.info("Library version report saved to: {}", reportPath);
                }
            }
            
            if (result.hasErrors()) {
                log.error("Library validation failed with {} errors", result.getErrors().size());
            } else if (result.hasWarnings()) {
                // Warnings теперь только для критических случаев (например, совместимые версии femsq-*)
                log.warn("Library validation completed with {} warnings", result.getWarnings().size());
            } else {
                log.info("Library validation passed successfully");
            }
            
        } catch (Exception e) {
            log.error("Failed to validate libraries", e);
            result.addError("Library validation failed: " + e.getMessage());
        }
        
        return result;
    }
    
    private static String extractVersionFromFilename(String filename) {
        // Извлекаем версию из имени файла: femsq-database-0.1.0.1-SNAPSHOT.jar -> 0.1.0.1-SNAPSHOT
        String nameWithoutExt = filename.replace(".jar", "");
        String[] parts = nameWithoutExt.split("-");
        if (parts.length >= 2) {
            // Берём последние части как версию
            return String.join("-", Arrays.copyOfRange(parts, parts.length - 2, parts.length));
        }
        return "unknown";
    }
    
    /**
     * Результат проверки библиотек.
     */
    public static class ValidationResult {
        private final List<String> errors = new ArrayList<>();
        private final List<String> warnings = new ArrayList<>();
        
        public void addError(String error) {
            errors.add(error);
        }
        
        public void addWarning(String warning) {
            warnings.add(warning);
        }
        
        public boolean hasErrors() {
            return !errors.isEmpty();
        }
        
        public boolean hasWarnings() {
            return !warnings.isEmpty();
        }
        
        public List<String> getErrors() {
            return Collections.unmodifiableList(errors);
        }
        
        public List<String> getWarnings() {
            return Collections.unmodifiableList(warnings);
        }
        
        public boolean isValid() {
            return !hasErrors();
        }
    }
}
