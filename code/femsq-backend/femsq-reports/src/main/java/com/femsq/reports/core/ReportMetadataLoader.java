package com.femsq.reports.core;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.femsq.reports.model.ReportMetadata;
import com.femsq.reports.model.ReportParameter;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.xml.JRXmlLoader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Загрузчик метаданных отчётов.
 * 
 * <p>Загружает метаданные из JSON файлов и извлекает параметры из JRXML
 * в качестве fallback. Поддерживает парсинг динамических значений
 * (${today}, ${firstDayOfQuarter} и т.д.).
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@Component
public class ReportMetadataLoader {

    private static final Logger log = LoggerFactory.getLogger(ReportMetadataLoader.class);
    
    private final ObjectMapper objectMapper;

    public ReportMetadataLoader() {
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Загружает метаданные из JSON файла.
     * 
     * @param jsonFile путь к JSON файлу с метаданными
     * @return ReportMetadata или null если файл не найден или некорректен
     */
    public ReportMetadata loadFromJson(Path jsonFile) {
        if (!Files.exists(jsonFile)) {
            log.debug("Metadata file not found: {}", jsonFile);
            return null;
        }

        try {
            JsonNode root = objectMapper.readTree(jsonFile.toFile());
            
            // Поддерживаем две структуры:
            // 1. Корневая структура (данные отчёта в корне JSON)
            // 2. Структура с узлом "report" (данные отчёта в узле "report")
            JsonNode reportNode = root.has("report") ? root.get("report") : root;
            
            if (reportNode == null || reportNode.isEmpty()) {
                log.warn("Invalid JSON structure: missing report data in {}", jsonFile);
                return null;
            }

            // Валидация структуры
            if (!validateJsonStructure(reportNode)) {
                log.warn("Invalid JSON structure in {}", jsonFile);
                return null;
            }

            return parseMetadata(reportNode, jsonFile);
            
        } catch (IOException e) {
            log.error("Failed to load metadata from {}", jsonFile, e);
            return null;
        }
    }

    /**
     * Загружает метаданные из JSON файла по имени (ищет рядом с JRXML).
     * 
     * @param jrxmlFile путь к JRXML файлу
     * @return ReportMetadata или null если JSON не найден
     */
    public ReportMetadata loadFromJsonForJrxml(Path jrxmlFile) {
        String baseName = getBaseName(jrxmlFile);
        Path jsonFile = jrxmlFile.resolveSibling(baseName + ".json");
        return loadFromJson(jsonFile);
    }

    /**
     * Загружает метаданные из InputStream (для classpath ресурсов).
     * 
     * @param inputStream поток с JSON данными
     * @param reportId идентификатор отчёта (для логирования)
     * @return ReportMetadata или null если данные некорректны
     */
    public ReportMetadata loadFromJson(InputStream inputStream, String reportId) {
        try {
            JsonNode root = objectMapper.readTree(inputStream);
            
            // Поддерживаем две структуры:
            // 1. Корневая структура (данные отчёта в корне JSON)
            // 2. Структура с узлом "report" (данные отчёта в узле "report")
            JsonNode reportNode = root.has("report") ? root.get("report") : root;
            
            if (reportNode == null || reportNode.isEmpty()) {
                log.warn("Invalid JSON structure: missing report data for reportId: {}", reportId);
                return null;
            }

            // Валидация структуры
            if (!validateJsonStructure(reportNode)) {
                log.warn("Invalid JSON structure for reportId: {}", reportId);
                return null;
            }

            return parseMetadata(reportNode, reportId);
            
        } catch (IOException e) {
            log.error("Failed to load metadata from InputStream for reportId: {}", reportId, e);
            return null;
        }
    }

    /**
     * Извлекает метаданные из JRXML файла (fallback).
     * 
     * @param jrxmlFile путь к JRXML файлу
     * @return ReportMetadata с базовой информацией и параметрами из JRXML
     */
    public ReportMetadata extractFromJrxml(Path jrxmlFile) {
        if (!Files.exists(jrxmlFile)) {
            log.debug("JRXML file not found: {}", jrxmlFile);
            return null;
        }

        try (InputStream is = Files.newInputStream(jrxmlFile)) {
            JasperDesign design = JRXmlLoader.load(is);
            
            String reportId = getBaseName(jrxmlFile);
            String reportName = design.getName() != null ? design.getName() : reportId;
            
            return ReportMetadata.minimal(
                    reportId,
                    reportName,
                    "Автоматически определено из JRXML",
                    jrxmlFile.getFileName().toString()
            );
            
        } catch (IOException | JRException e) {
            log.error("Failed to extract metadata from JRXML: {}", jrxmlFile, e);
            return null;
        }
    }

    /**
     * Загружает метаданные: сначала из JSON, если не найден - из JRXML.
     * 
     * @param jrxmlFile путь к JRXML файлу
     * @return ReportMetadata или null если оба источника недоступны
     */
    public ReportMetadata loadMetadata(Path jrxmlFile) {
        // Пытаемся загрузить из JSON
        ReportMetadata metadata = loadFromJsonForJrxml(jrxmlFile);
        
        if (metadata != null) {
            return metadata;
        }
        
        // Fallback: извлекаем из JRXML
        log.debug("JSON metadata not found for {}, extracting from JRXML", jrxmlFile);
        return extractFromJrxml(jrxmlFile);
    }

    /**
     * Разрешает динамические значения по умолчанию для списка параметров.
     * 
     * @param parameters список параметров
     * @param context    контекст для разрешения динамических значений (например, contractorId)
     * @return список параметров с разрешёнными значениями по умолчанию
     */
    public List<ReportParameter> resolveDefaultValues(
            List<ReportParameter> parameters, 
            Map<String, String> context
    ) {
        if (parameters == null || parameters.isEmpty()) {
            return List.of();
        }
        
        return parameters.stream()
                .map(param -> {
                    String resolvedDefaultValue = param.defaultValue();
                    if (resolvedDefaultValue != null && resolvedDefaultValue.contains("${")) {
                        resolvedDefaultValue = parseDynamicValueWithContext(
                                resolvedDefaultValue, 
                                context
                        );
                    }
                    
                    return new ReportParameter(
                            param.name(),
                            param.type(),
                            param.label(),
                            param.description(),
                            param.required(),
                            resolvedDefaultValue,
                            param.validation(),
                            param.options(),
                            param.source()
                    );
                })
                .collect(java.util.stream.Collectors.toList());
    }

    /**
     * Парсит динамическое значение с учётом контекста.
     * 
     * @param value   значение с возможным выражением
     * @param context контекст для разрешения динамических значений
     * @return распарсенное значение или исходное, если не выражение
     */
    private String parseDynamicValueWithContext(String value, Map<String, String> context) {
        if (value == null || !value.contains("${")) {
            return value;
        }
        
        // Используем regex для поиска всех выражений ${...}
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\$\\{([^}]+)\\}");
        java.util.regex.Matcher matcher = pattern.matcher(value);
        StringBuffer result = new StringBuffer();
        
        while (matcher.find()) {
            String expression = matcher.group(1);
            String resolved = resolveExpression(expression, context);
            matcher.appendReplacement(result, java.util.regex.Matcher.quoteReplacement(resolved != null ? resolved : ""));
        }
        matcher.appendTail(result);
        
        return result.toString();
    }

    /**
     * Разрешает выражение с учётом контекста.
     * 
     * @param expression выражение для разрешения
     * @param context    контекст для разрешения
     * @return разрешённое значение или null
     */
    private String resolveExpression(String expression, Map<String, String> context) {
        // Сначала проверяем стандартные выражения
        String standardValue = parseDynamicValue("${" + expression + "}");
        if (!standardValue.equals("${" + expression + "}")) {
            return standardValue;
        }
        
        // Затем проверяем контекст
        if (context != null && context.containsKey(expression)) {
            return context.get(expression);
        }
        
        log.warn("Unknown dynamic expression: {}", expression);
        return null;
    }

    /**
     * Парсит динамическое значение (${today}, ${firstDayOfQuarter} и т.д.).
     * 
     * @param value значение с возможным выражением
     * @return распарсенное значение или исходное, если не выражение
     */
    public String parseDynamicValue(String value) {
        if (value == null || !value.startsWith("${") || !value.endsWith("}")) {
            return value;
        }

        String expression = value.substring(2, value.length() - 1);
        
        return switch (expression) {
            case "today" -> LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "yesterday" -> LocalDate.now().minusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "firstDayOfMonth" -> LocalDate.now().withDayOfMonth(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "lastDayOfMonth" -> LocalDate.now().withDayOfMonth(LocalDate.now().lengthOfMonth())
                    .format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "firstDayOfQuarter" -> getFirstDayOfQuarter().format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "lastDayOfQuarter" -> getLastDayOfQuarter().format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "firstDayOfYear" -> LocalDate.now().withDayOfYear(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
            case "lastDayOfYear" -> LocalDate.now().withDayOfYear(LocalDate.now().lengthOfYear())
                    .format(DateTimeFormatter.ISO_LOCAL_DATE);
            default -> {
                log.warn("Unknown dynamic expression: {}", expression);
                yield value; // Возвращаем исходное значение
            }
        };
    }

    // Private helper methods

    private boolean validateJsonStructure(JsonNode reportNode) {
        // Проверяем обязательные поля
        if (!reportNode.has("id") || !reportNode.get("id").isTextual()) {
            log.warn("Missing or invalid 'id' field");
            return false;
        }
        
        if (!reportNode.has("name") || !reportNode.get("name").isTextual()) {
            log.warn("Missing or invalid 'name' field");
            return false;
        }
        
        if (!reportNode.has("files")) {
            log.warn("Missing 'files' field");
            return false;
        }
        
        JsonNode filesNode = reportNode.get("files");
        if (!filesNode.has("template") || !filesNode.get("template").isTextual()) {
            log.warn("Missing or invalid 'files.template' field");
            return false;
        }
        
        return true;
    }

    private ReportMetadata parseMetadata(JsonNode reportNode, Path jsonFile) {
        return parseMetadata(reportNode, jsonFile != null ? jsonFile.toString() : null);
    }

    private ReportMetadata parseMetadata(JsonNode reportNode, String reportId) {
        String id = reportNode.get("id").asText();
        String name = reportNode.get("name").asText();
        String description = reportNode.path("description").asText(null);
        String category = reportNode.path("category").asText(null);
        String author = reportNode.path("author").asText(null);
        String created = reportNode.path("created").asText(null);
        String lastModified = reportNode.path("lastModified").asText(null);
        String version = reportNode.path("version").asText("1.0.0");
        String accessLevel = reportNode.path("accessLevel").asText("user");

        // Парсим файлы
        JsonNode filesNode = reportNode.get("files");
        ReportMetadata.Files files = new ReportMetadata.Files(
                filesNode.get("template").asText(),
                filesNode.path("compiled").asText(null),
                filesNode.path("thumbnail").asText(null)
        );

        // Парсим параметры
        List<ReportParameter> parameters = new ArrayList<>();
        if (reportNode.has("parameters") && reportNode.get("parameters").isArray()) {
            for (JsonNode paramNode : reportNode.get("parameters")) {
                ReportParameter param = parseParameter(paramNode);
                if (param != null) {
                    parameters.add(param);
                }
            }
        }

        // Парсим UI интеграцию
        ReportMetadata.UiIntegration uiIntegration = parseUiIntegration(
                reportNode.path("uiIntegration")
        );

        // Парсим теги
        List<String> tags = new ArrayList<>();
        if (reportNode.has("tags") && reportNode.get("tags").isArray()) {
            for (JsonNode tagNode : reportNode.get("tags")) {
                if (tagNode.isTextual()) {
                    tags.add(tagNode.asText());
                }
            }
        }

        return new ReportMetadata(
                id,
                version,
                name,
                description,
                category,
                author,
                created,
                lastModified,
                files,
                parameters,
                uiIntegration,
                tags,
                accessLevel
        );
    }

    private ReportParameter parseParameter(JsonNode paramNode) {
        if (!paramNode.has("name") || !paramNode.has("type")) {
            log.warn("Parameter missing 'name' or 'type'");
            return null;
        }

        String name = paramNode.get("name").asText();
        String type = paramNode.get("type").asText();
        String label = paramNode.path("label").asText(name);
        String description = paramNode.path("description").asText(null);
        boolean required = paramNode.path("required").asBoolean(false);
        
        // Парсим defaultValue с поддержкой динамических значений
        String defaultValue = paramNode.path("defaultValue").asText(null);
        if (defaultValue != null) {
            defaultValue = parseDynamicValue(defaultValue);
        }

        // Парсим валидацию
        ReportParameter.Validation validation = parseValidation(
                paramNode.path("validation")
        );

        // Парсим опции для enum
        List<ReportParameter.Option> options = null;
        if (paramNode.has("options") && paramNode.get("options").isArray()) {
            options = new ArrayList<>();
            for (JsonNode optionNode : paramNode.get("options")) {
                String value = optionNode.path("value").asText();
                String optionLabel = optionNode.path("label").asText(value);
                options.add(new ReportParameter.Option(value, optionLabel));
            }
        }

        // Парсим источник данных
        ReportParameter.Source source = parseSource(paramNode.path("source"));

        return new ReportParameter(
                name,
                type,
                label,
                description,
                required,
                defaultValue,
                validation,
                options,
                source
        );
    }

    private ReportParameter.Validation parseValidation(JsonNode validationNode) {
        if (validationNode.isMissingNode() || validationNode.isEmpty()) {
            return ReportParameter.Validation.empty();
        }

        return new ReportParameter.Validation(
                validationNode.path("minDate").asText(null),
                validationNode.path("maxDate").asText(null),
                validationNode.path("min").isNumber() ? 
                        validationNode.get("min").numberValue() : null,
                validationNode.path("max").isNumber() ? 
                        validationNode.get("max").numberValue() : null,
                validationNode.path("pattern").asText(null)
        );
    }

    private ReportParameter.Source parseSource(JsonNode sourceNode) {
        if (sourceNode.isMissingNode() || sourceNode.isEmpty()) {
            return null;
        }

        return new ReportParameter.Source(
                sourceNode.path("type").asText(null),
                sourceNode.path("endpoint").asText(null),
                sourceNode.path("valueField").asText(null),
                sourceNode.path("labelField").asText(null)
        );
    }

    private ReportMetadata.UiIntegration parseUiIntegration(JsonNode uiNode) {
        if (uiNode.isMissingNode() || uiNode.isEmpty()) {
            return new ReportMetadata.UiIntegration(true, List.of());
        }

        boolean showInReportsList = uiNode.path("showInReportsList").asBoolean(true);
        
        List<ReportMetadata.UiIntegration.ContextMenu> contextMenus = new ArrayList<>();
        if (uiNode.has("contextMenus") && uiNode.get("contextMenus").isArray()) {
            for (JsonNode menuNode : uiNode.get("contextMenus")) {
                String component = menuNode.path("component").asText(null);
                String label = menuNode.path("label").asText(null);
                String icon = menuNode.path("icon").asText(null);
                
                Map<String, String> parameterMapping = new HashMap<>();
                if (menuNode.has("parameterMapping") && menuNode.get("parameterMapping").isObject()) {
                    menuNode.get("parameterMapping").fields().forEachRemaining(entry -> {
                        parameterMapping.put(entry.getKey(), entry.getValue().asText());
                    });
                }
                
                contextMenus.add(new ReportMetadata.UiIntegration.ContextMenu(
                        component, label, icon, parameterMapping
                ));
            }
        }

        return new ReportMetadata.UiIntegration(showInReportsList, contextMenus);
    }

    private String getBaseName(Path file) {
        String fileName = file.getFileName().toString();
        int lastDot = fileName.lastIndexOf('.');
        return lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
    }

    private LocalDate getFirstDayOfQuarter() {
        LocalDate now = LocalDate.now();
        int month = now.getMonthValue();
        int quarter = (month - 1) / 3;
        int firstMonth = quarter * 3 + 1;
        return LocalDate.of(now.getYear(), firstMonth, 1);
    }

    private LocalDate getLastDayOfQuarter() {
        LocalDate firstDay = getFirstDayOfQuarter();
        return firstDay.plusMonths(3).minusDays(1);
    }
}
