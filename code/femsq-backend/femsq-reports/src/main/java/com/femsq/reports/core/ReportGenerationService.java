package com.femsq.reports.core;

import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportGenerationRequest;
import com.femsq.reports.model.ReportMetadata;
import com.femsq.reports.model.ReportParameter;
import com.femsq.reports.model.ReportResult;
import jakarta.annotation.PostConstruct;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.export.HtmlExporter;
import net.sf.jasperreports.engine.export.ooxml.JRXlsxExporter;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.export.*;
import net.sf.jasperreports.pdf.JRPdfExporter;
import net.sf.jasperreports.pdf.SimplePdfExporterConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.FileTime;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.*;
import java.util.concurrent.*;

/**
 * Сервис генерации отчётов.
 * 
 * <p>Обеспечивает генерацию отчётов в различных форматах (PDF, Excel, HTML)
 * с поддержкой валидации параметров, таймаутов и ограничений на количество
 * одновременных генераций.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@Service
public class ReportGenerationService {

    private static final Logger log = LoggerFactory.getLogger(ReportGenerationService.class);

    private static final String BUILD_MARKER = "reports-build-2025-11-24-03";

    private final ReportsProperties properties;
    private final ReportDiscoveryService discoveryService;
    private final JasperReportsEngine jasperEngine;
    private final DataSource dataSource; // Может быть null, если подключение динамическое
    private final ConnectionFactory connectionFactory; // Для получения Connection при динамическом подключении
    private final DatabaseConfigurationService databaseConfigService; // Для получения schema из конфигурации
    private final ResourceLoader resourceLoader;

    /**
     * Директория для временных копий встроенных шаблонов.
     */
    private Path embeddedTemplatesCacheDir;

    /**
     * Семафор для ограничения количества одновременных генераций.
     */
    private Semaphore generationSemaphore;

    /**
     * ExecutorService для выполнения генераций с таймаутами.
     */
    private ExecutorService executorService;

    public ReportGenerationService(
            ReportsProperties properties,
            ReportDiscoveryService discoveryService,
            JasperReportsEngine jasperEngine,
            @Autowired(required = false) DataSource dataSource,
            @Autowired(required = false) ConnectionFactory connectionFactory,
            @Autowired(required = false) DatabaseConfigurationService databaseConfigService,
            ResourceLoader resourceLoader
    ) {
        this.properties = properties;
        this.discoveryService = discoveryService;
        this.jasperEngine = jasperEngine;
        this.dataSource = dataSource;
        this.connectionFactory = connectionFactory;
        this.databaseConfigService = databaseConfigService;
        this.resourceLoader = resourceLoader;
    }

    /**
     * Инициализация сервиса при старте приложения.
     */
    @PostConstruct
    public void initialize() {
        int maxConcurrent = properties.getGeneration().getMaxConcurrent();
        this.generationSemaphore = new Semaphore(maxConcurrent);
        this.executorService = Executors.newFixedThreadPool(maxConcurrent);
        this.embeddedTemplatesCacheDir = properties.getGeneration()
                .getTempDirectoryAsPath()
                .resolve("embedded-templates");
        try {
            if (!Files.exists(this.embeddedTemplatesCacheDir)) {
                Files.createDirectories(this.embeddedTemplatesCacheDir);
            }
            preloadEmbeddedTemplates();
        } catch (IOException e) {
            log.warn("Failed to prepare embedded templates cache directory: {}", embeddedTemplatesCacheDir, e);
        }
        log.info("ReportGenerationService initialized (marker={}) maxConcurrent={}", BUILD_MARKER, maxConcurrent);
    }

    /**
     * Генерирует отчёт на основе запроса.
     * 
     * @param request запрос на генерацию отчёта
     * @return результат генерации отчёта
     * @throws JRException если генерация не удалась
     * @throws IllegalArgumentException если запрос невалиден
     * @throws TimeoutException если генерация превысила таймаут
     */
    public ReportResult generateReport(ReportGenerationRequest request) 
            throws JRException, IllegalArgumentException, TimeoutException {
        
        log.info("Generating report: id={}, format={}", request.reportId(), request.format());

        // 1. Получаем метаданные отчёта
        ReportMetadata metadata = discoveryService.getMetadata(request.reportId());
        if (metadata == null) {
            throw new IllegalArgumentException("Report not found: " + request.reportId());
        }

        // 2. Валидируем параметры
        validateParameters(metadata, request.parameters());

        // 3. Получаем путь к шаблону
        Path templatePath = getTemplatePath(metadata);

        // 4. Генерируем отчёт с таймаутом и ограничением параллелизма
        return generateWithTimeout(templatePath, request, metadata);
    }

    /**
     * Генерирует preview отчёта (первая страница).
     * 
     * @param reportId идентификатор отчёта
     * @param parameters параметры отчёта
     * @return результат генерации preview (PDF формат)
     * @throws JRException если генерация не удалась
     */
    public ReportResult generatePreview(String reportId, Map<String, Object> parameters) 
            throws JRException {
        
        log.info("Generating preview for report: {}", reportId);

        ReportMetadata metadata = discoveryService.getMetadata(reportId);
        if (metadata == null) {
            throw new IllegalArgumentException("Report not found: " + reportId);
        }

        Path templatePath = getTemplatePath(metadata);
        // Если это предкомпилированный .jasper файл, загружаем его напрямую
        JasperReport report;
        if (templatePath.toString().endsWith(".jasper")) {
            log.debug("[{}] Loading precompiled .jasper file: {}", BUILD_MARKER, templatePath);
            try (java.io.InputStream is = Files.newInputStream(templatePath)) {
                report = (JasperReport) net.sf.jasperreports.engine.util.JRLoader.loadObject(is);
            } catch (java.io.IOException e) {
                throw new RuntimeException("Failed to load precompiled report: " + templatePath, e);
            }
        } else {
            // Компилируем из .jrxml
            report = jasperEngine.compileReport(templatePath);
        }

        // Генерируем только первую страницу
        Map<String, Object> params = prepareParameters(metadata, parameters);
        JasperPrint jasperPrint;
        try (Connection connection = getConnection()) {
            jasperPrint = JasperFillManager.fillReport(report, params, connection);
        } catch (JRException | SQLException e) {
            throw new RuntimeException("Failed to fill report: " + reportId, e);
        }

        // Ограничиваем до первой страницы для preview
        // JasperPrint не имеет метода setPages, поэтому создаём новый объект с одной страницей
        if (jasperPrint.getPages().size() > 1) {
            // Создаём новый JasperPrint с только первой страницей
            JasperPrint previewPrint = new JasperPrint();
            previewPrint.setName(jasperPrint.getName());
            previewPrint.setPageWidth(jasperPrint.getPageWidth());
            previewPrint.setPageHeight(jasperPrint.getPageHeight());
            if (jasperPrint.getTimeZoneId() != null) {
                previewPrint.setTimeZoneId(jasperPrint.getTimeZoneId());
            }
            previewPrint.addPage(jasperPrint.getPages().get(0));
            jasperPrint = previewPrint;
        }

        // Экспортируем в PDF
        byte[] content = exportToPdf(jasperPrint);
        
        return ReportResult.now(reportId, "pdf", content);
    }

    /**
     * Генерирует отчёт с таймаутом и ограничением параллелизма.
     */
    private ReportResult generateWithTimeout(
            Path templatePath,
            ReportGenerationRequest request,
            ReportMetadata metadata
    ) throws JRException, TimeoutException {
        
        long timeout = properties.getGeneration().getTimeout();
        
        Future<ReportResult> future = executorService.submit(() -> {
            try {
                // Получаем разрешение на генерацию
                generationSemaphore.acquire();
                try {
                    return generateReportInternal(templatePath, request, metadata);
                } finally {
                    generationSemaphore.release();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new JRException("Report generation interrupted", e);
            }
        });

        try {
            return future.get(timeout, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            future.cancel(true);
            Thread.currentThread().interrupt();
            throw new JRException("Report generation interrupted", e);
        } catch (ExecutionException e) {
            Throwable cause = e.getCause();
            if (cause instanceof JRException) {
                throw (JRException) cause;
            }
            throw new JRException("Report generation failed", cause);
        } catch (java.util.concurrent.TimeoutException e) {
            future.cancel(true);
            throw new TimeoutException("Report generation exceeded timeout: " + timeout + "ms");
        }
    }

    /**
     * Внутренний метод генерации отчёта.
     */
    private ReportResult generateReportInternal(
            Path templatePath,
            ReportGenerationRequest request,
            ReportMetadata metadata
    ) throws JRException {
        
        // 1. Загружаем или компилируем шаблон
        JasperReport report;
        if (templatePath.toString().endsWith(".jasper")) {
            log.debug("[{}] Loading precompiled .jasper file: {}", BUILD_MARKER, templatePath);
            try (java.io.InputStream is = Files.newInputStream(templatePath)) {
                report = (JasperReport) JRLoader.loadObject(is);
            } catch (java.io.IOException e) {
                throw new JRException("Failed to load precompiled report: " + templatePath, e);
            }
        } else {
            // Компилируем из .jrxml
            report = jasperEngine.compileReport(templatePath);
        }

        // 2. Подготавливаем параметры
        Map<String, Object> params = prepareParameters(metadata, request.parameters());

        // 3. Заполняем отчёт данными
        JasperPrint jasperPrint;
        try (Connection connection = getConnection()) {
            jasperPrint = JasperFillManager.fillReport(report, params, connection);
        } catch (Exception e) {
            throw new JRException("Failed to fill report with data", e);
        }

        // 4. Экспортируем в нужный формат
        byte[] content = switch (request.format().toLowerCase()) {
            case "pdf" -> exportToPdf(jasperPrint);
            case "excel", "xls", "xlsx" -> exportToExcel(jasperPrint);
            case "html" -> exportToHtml(jasperPrint);
            default -> throw new IllegalArgumentException("Unsupported format: " + request.format());
        };

        // 5. Создаём результат
        return ReportResult.now(request.reportId(), request.format(), content);
    }

    /**
     * Получает Connection для работы с БД.
     * Использует DataSource, если доступен, иначе ConnectionFactory.
     * 
     * <p>В приложении FEMSQ подключение к БД настраивается динамически через UI,
     * поэтому DataSource может отсутствовать. В этом случае используется ConnectionFactory
     * из модуля database, который управляет подключениями через ConnectionManager.
     * 
     * @return Connection к базе данных
     * @throws SQLException если не удалось получить подключение
     */
    private Connection getConnection() throws SQLException {
        if (dataSource != null) {
            return dataSource.getConnection();
        }
        if (connectionFactory != null) {
            try {
                return connectionFactory.createConnection();
            } catch (com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException e) {
                throw new SQLException("Database connection not configured. Please connect to database first.", e);
            }
        }
        throw new SQLException("No DataSource or ConnectionFactory available. Database connection must be configured.");
    }

    /**
     * Экспортирует отчёт в PDF.
     */
    private byte[] exportToPdf(JasperPrint jasperPrint) throws JRException {
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            JRPdfExporter exporter = new JRPdfExporter();
            exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
            exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(outputStream));
            
            SimplePdfExporterConfiguration configuration = new SimplePdfExporterConfiguration();
            exporter.setConfiguration(configuration);
            
            exporter.exportReport();
            
            return outputStream.toByteArray();
        } catch (IOException e) {
            throw new JRException("Failed to export report to PDF", e);
        }
    }

    /**
     * Экспортирует отчёт в Excel.
     */
    private byte[] exportToExcel(JasperPrint jasperPrint) throws JRException {
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            JRXlsxExporter exporter = new JRXlsxExporter();
            exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
            exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(outputStream));
            
            SimpleXlsxReportConfiguration configuration = new SimpleXlsxReportConfiguration();
            configuration.setOnePagePerSheet(false);
            configuration.setRemoveEmptySpaceBetweenRows(true);
            exporter.setConfiguration(configuration);
            
            exporter.exportReport();
            
            return outputStream.toByteArray();
        } catch (IOException e) {
            throw new JRException("Failed to export report to Excel", e);
        }
    }

    /**
     * Экспортирует отчёт в HTML.
     */
    private byte[] exportToHtml(JasperPrint jasperPrint) throws JRException {
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            HtmlExporter exporter = new HtmlExporter();
            exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
            exporter.setExporterOutput(new SimpleHtmlExporterOutput(outputStream));
            
            SimpleHtmlExporterConfiguration configuration = new SimpleHtmlExporterConfiguration();
            exporter.setConfiguration(configuration);
            
            exporter.exportReport();
            
            return outputStream.toByteArray();
        } catch (IOException e) {
            throw new JRException("Failed to export report to HTML", e);
        }
    }

    /**
     * Валидирует параметры отчёта.
     */
    private void validateParameters(ReportMetadata metadata, Map<String, Object> providedParams) {
        if (metadata.parameters() == null || metadata.parameters().isEmpty()) {
            return; // Нет параметров для валидации
        }

        List<String> errors = new ArrayList<>();

        for (ReportParameter param : metadata.parameters()) {
            Object value = providedParams.get(param.name());

            // Проверка обязательных параметров
            if (param.required() && (value == null || (value instanceof String && ((String) value).isBlank()))) {
                errors.add("Required parameter missing: " + param.name());
                continue;
            }

            if (value == null) {
                continue; // Необязательный параметр без значения
            }

            // Проверка типа
            if (!isValidType(value, param.type())) {
                errors.add("Invalid type for parameter '" + param.name() + "': expected " + param.type() + ", got " + value.getClass().getSimpleName());
            }

            // Проверка валидации (если есть)
            if (param.validation() != null) {
                validateParameterValue(param, value, errors);
            }
        }

        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Parameter validation failed: " + String.join(", ", errors));
        }
    }

    /**
     * Проверяет соответствие типа значения типу параметра.
     */
    private boolean isValidType(Object value, String expectedType) {
        return switch (expectedType.toLowerCase()) {
            case "string" -> value instanceof String;
            case "integer", "int" -> value instanceof Integer;
            case "long" -> value instanceof Long || value instanceof Integer;
            case "double", "float" -> value instanceof Double || value instanceof Float || value instanceof Number;
            case "boolean" -> value instanceof Boolean;
            case "date" -> value instanceof java.util.Date || value instanceof java.time.LocalDate;
            default -> true; // Неизвестный тип - пропускаем проверку
        };
    }

    /**
     * Валидирует значение параметра по правилам валидации.
     */
    private void validateParameterValue(ReportParameter param, Object value, List<String> errors) {
        ReportParameter.Validation validation = param.validation();
        if (validation == null) {
            return;
        }

        String paramName = param.name();

        // Проверка числовых диапазонов
        if (value instanceof Number number) {
            double numValue = number.doubleValue();
            if (validation.min() != null && numValue < validation.min().doubleValue()) {
                errors.add("Parameter '" + paramName + "' is less than minimum: " + validation.min());
            }
            if (validation.max() != null && numValue > validation.max().doubleValue()) {
                errors.add("Parameter '" + paramName + "' is greater than maximum: " + validation.max());
            }
        }

        // Проверка строкового паттерна
        if (value instanceof String stringValue && validation.pattern() != null) {
            if (!stringValue.matches(validation.pattern())) {
                errors.add("Parameter '" + paramName + "' does not match pattern: " + validation.pattern());
            }
        }

        // Проверка дат
        if (value instanceof java.time.LocalDate dateValue) {
            if (validation.minDate() != null) {
                java.time.LocalDate minDate = java.time.LocalDate.parse(validation.minDate());
                if (dateValue.isBefore(minDate)) {
                    errors.add("Parameter '" + paramName + "' is before minimum date: " + validation.minDate());
                }
            }
            if (validation.maxDate() != null) {
                java.time.LocalDate maxDate = java.time.LocalDate.parse(validation.maxDate());
                if (dateValue.isAfter(maxDate)) {
                    errors.add("Parameter '" + paramName + "' is after maximum date: " + validation.maxDate());
                }
            }
        }
    }

    /**
     * Подготавливает параметры для отчёта, включая значения по умолчанию и SCHEMA_NAME.
     */
    private Map<String, Object> prepareParameters(ReportMetadata metadata, Map<String, Object> providedParams) {
        Map<String, Object> params = new HashMap<>(providedParams != null ? providedParams : Map.of());

        // 1. Добавляем параметры по умолчанию из метаданных (если не предоставлены)
        if (metadata.parameters() != null) {
            for (ReportParameter param : metadata.parameters()) {
                // Если параметр не предоставлен, используем значение по умолчанию
                if (!params.containsKey(param.name()) && param.defaultValue() != null) {
                    Object defaultValue = parseDefaultValue(param.defaultValue(), param.type());
                    params.put(param.name(), defaultValue);
                }
            }
        }

        // 2. Добавляем SCHEMA_NAME из конфигурации БД (ПОСЛЕ параметров метаданных, чтобы перезаписать дефолт)
        if (databaseConfigService != null) {
            try {
                String schema = databaseConfigService.loadConfig().schema();
                if (schema != null && !schema.isBlank()) {
                    params.put("SCHEMA_NAME", schema);
                    log.info("Added SCHEMA_NAME parameter from DB config: {}", schema);
                } else {
                    params.put("SCHEMA_NAME", "ags"); // Fallback к дефолтной схеме если schema == null
                    log.warn("Database schema is null/blank, using default 'ags'");
                }
            } catch (Exception e) {
                log.warn("Failed to get schema from DatabaseConfigurationService, using default 'ags': {}", e.getMessage());
                params.put("SCHEMA_NAME", "ags"); // Fallback к дефолтной схеме при ошибке
            }
        } else {
            // Если нет databaseConfigService, используем дефолтную схему
            params.put("SCHEMA_NAME", "ags");
            log.warn("DatabaseConfigurationService is null, using default schema 'ags'");
        }

        // 3. Добавляем SUBREPORT_DIR для отчётов с подотчётами
        if (!params.containsKey("SUBREPORT_DIR")) {
            String baseDir;
            if (embeddedTemplatesCacheDir != null) {
                baseDir = embeddedTemplatesCacheDir.toAbsolutePath().toString() + File.separator;
            } else {
                baseDir = properties.getGeneration()
                        .getTempDirectoryAsPath()
                        .resolve("embedded-templates")
                        .toAbsolutePath()
                        .toString() + File.separator;
            }
            params.put("SUBREPORT_DIR", baseDir);
            log.debug("Added SUBREPORT_DIR parameter: {}", baseDir);
        }

        log.debug("Resolved report parameters: {}", params);

        return params;
    }

    /**
     * Парсит значение по умолчанию в нужный тип.
     */
    private Object parseDefaultValue(String defaultValue, String type) {
        return switch (type.toLowerCase()) {
            case "integer", "int" -> Integer.parseInt(defaultValue);
            case "long" -> Long.parseLong(defaultValue);
            case "double", "float" -> Double.parseDouble(defaultValue);
            case "boolean" -> Boolean.parseBoolean(defaultValue);
            case "date" -> java.time.LocalDate.parse(defaultValue);
            default -> defaultValue; // String или неизвестный тип
        };
    }

    /**
     * Получает путь к шаблону отчёта.
     * Сначала ищет предкомпилированный .jasper файл, затем .jrxml.
     */
    private Path getTemplatePath(ReportMetadata metadata) {
        String templateFile = metadata.files().template();
        log.info("[{}] getTemplatePath: looking for template: {}", BUILD_MARKER, templateFile);
        
        // Проверяем внешние отчёты
        Path externalPath = properties.getExternal().getPathAsPath();
        Path templatePath = externalPath.resolve(templateFile);
        
        log.debug("[{}] Checking external path: {}", BUILD_MARKER, templatePath);
        if (Files.exists(templatePath)) {
            log.info("[{}] Found template in external directory: {}", BUILD_MARKER, templatePath);
            return templatePath;
        }

        // Если не найден во внешних, ищем встроенные (classpath или файловая система)
        ReportsProperties.Embedded embeddedProps = properties.getEmbedded();
        if (embeddedProps == null || embeddedProps.getPath() == null || embeddedProps.getPath().isBlank()) {
            log.error("[{}] Embedded reports path not configured", BUILD_MARKER);
            throw new IllegalArgumentException("Template file not found: " + templateFile);
        }

        String embeddedPath = embeddedProps.getPath().trim();
        log.info("[{}] Embedded reports path: {}", BUILD_MARKER, embeddedPath);
        
        // Сначала пытаемся найти предкомпилированный .jasper файл
        String jasperFile = templateFile.replace(".jrxml", ".jasper");
        Resource jasperResource = findEmbeddedResource(embeddedPath, jasperFile);
        if (jasperResource != null && jasperResource.exists()) {
            log.info("[{}] Found precompiled .jasper file: {}", BUILD_MARKER, jasperFile);
            Path cachedPath = copyEmbeddedTemplateToCache(jasperFile, jasperResource);
            log.info("[{}] Using precompiled template from: {}", BUILD_MARKER, cachedPath);
            return cachedPath;
        }
        
        // Если .jasper не найден, ищем .jrxml
        Resource resource = findEmbeddedResource(embeddedPath, templateFile);
        
        if (resource != null && resource.exists()) {
            log.info("[{}] Using embedded template {} from {}", BUILD_MARKER, templateFile, resource.getDescription());
            Path cachedPath = copyEmbeddedTemplateToCache(templateFile, resource);
            log.info("[{}] Copied embedded template to: {}", BUILD_MARKER, cachedPath);
            return cachedPath;
        } else if (resource != null) {
            log.warn("[{}] Embedded template resource does not exist: {}", BUILD_MARKER, resource.getDescription());
        } else {
            log.warn("[{}] Failed to create resource for embedded template: {}", BUILD_MARKER, templateFile);
        }

        throw new IllegalArgumentException("Template file not found: " + templateFile);
    }
    
    /**
     * Ищет ресурс в embedded директории.
     */
    private Resource findEmbeddedResource(String embeddedPath, String fileName) {
        Resource resource = null;
        
        if (embeddedPath.startsWith("classpath:")) {
            String cpPath = embeddedPath.substring("classpath:".length());
            if (cpPath.startsWith("/")) {
                cpPath = cpPath.substring(1);
            }
            if (!cpPath.endsWith("/")) {
                cpPath = cpPath + "/";
            }
            String resourceLocation = "classpath:" + cpPath + fileName;
            log.debug("[{}] Trying embedded classpath resource: {}", BUILD_MARKER, resourceLocation);
            resource = resourceLoader.getResource(resourceLocation);
            if (resource != null) {
                log.debug("[{}] Resource loaded: {}, exists: {}", BUILD_MARKER, resource.getDescription(), resource.exists());
            }
        } else {
            Path embeddedDir = Paths.get(embeddedPath);
            Path candidate = embeddedDir.resolve(fileName);
            log.debug("[{}] Checking embedded filesystem path: {}", BUILD_MARKER, candidate);
            if (Files.exists(candidate)) {
                log.info("[{}] Found embedded resource on filesystem: {}", BUILD_MARKER, candidate);
                try {
                    resource = resourceLoader.getResource("file:" + candidate.toAbsolutePath());
                } catch (Exception e) {
                    log.debug("[{}] Failed to create resource from filesystem path: {}", BUILD_MARKER, candidate, e);
                }
            }
            // Попробуем также как classpath без префикса (на случай опечаток)
            if (resource == null || !resource.exists()) {
                String fallbackLocation = "classpath:" + embeddedPath + (embeddedPath.endsWith("/") ? "" : "/") + fileName;
                log.debug("[{}] Trying fallback classpath resource: {}", BUILD_MARKER, fallbackLocation);
                resource = resourceLoader.getResource(fallbackLocation);
                if (resource != null) {
                    log.debug("[{}] Fallback resource loaded: {}, exists: {}", BUILD_MARKER, resource.getDescription(), resource.exists());
                }
            }
        }
        
        return resource;
    }

    /**
     * Копирует встроенный шаблон из classpath в временную директорию и возвращает путь.
     */
    private Path copyEmbeddedTemplateToCache(String templateFile, Resource resource) {
        try {
            if (embeddedTemplatesCacheDir == null) {
                embeddedTemplatesCacheDir = properties.getGeneration()
                        .getTempDirectoryAsPath()
                        .resolve("embedded-templates");
            }
            Files.createDirectories(embeddedTemplatesCacheDir);
            Path cachedPath = embeddedTemplatesCacheDir.resolve(templateFile);
            Files.createDirectories(cachedPath.getParent());
            try (InputStream inputStream = resource.getInputStream()) {
                Files.copy(inputStream, cachedPath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
            ensureLocalJasperUpToDate(cachedPath);
            log.debug("Copied embedded template {} to {}", templateFile, cachedPath);
            return cachedPath;
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to load embedded template: " + templateFile, e);
        }
    }

    private void ensureLocalJasperUpToDate(Path jrxmlPath) {
        try {
            if (jrxmlPath == null || !Files.exists(jrxmlPath)) {
                return;
            }
            Path jasperPath = jrxmlPath.resolveSibling(
                    jrxmlPath.getFileName().toString().replace(".jrxml", ".jasper"));
            boolean needsCompile = true;
            if (Files.exists(jasperPath)) {
                FileTime jrxmlTime = Files.getLastModifiedTime(jrxmlPath);
                FileTime jasperTime = Files.getLastModifiedTime(jasperPath);
                needsCompile = jasperTime.toMillis() < jrxmlTime.toMillis();
            }
            if (needsCompile) {
                JasperCompileManager.compileReportToFile(jrxmlPath.toString(), jasperPath.toString());
                log.info("[{}] Compiled embedded template {} → {}", BUILD_MARKER, jrxmlPath.getFileName(), jasperPath.getFileName());
            }
        } catch (Exception e) {
            log.warn("[{}] Failed to compile embedded template {}: {}", BUILD_MARKER, jrxmlPath, e.getMessage());
        }
    }

    private void preloadEmbeddedTemplates() throws IOException {
        ReportsProperties.Embedded embedded = properties.getEmbedded();
        if (embedded == null || embedded.getPath() == null) {
            return;
        }
        String embeddedPath = embedded.getPath().trim();
        if (!embeddedPath.startsWith("classpath:")) {
            return; // Для файловой системы и так доступны
        }
        String cpPath = embeddedPath.substring("classpath:".length());
        if (cpPath.startsWith("/")) {
            cpPath = cpPath.substring(1);
        }
        if (!cpPath.endsWith("/")) {
            cpPath = cpPath + "/";
        }
        ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        Resource[] resources = resolver.getResources("classpath:" + cpPath + "*.jrxml");
        for (Resource resource : resources) {
            String filename = resource.getFilename();
            if (filename == null) {
                continue;
            }
            try {
                copyEmbeddedTemplateToCache(filename, resource);
            } catch (Exception e) {
                log.warn("[{}] Failed to preload embedded template {}: {}", BUILD_MARKER, filename, e.getMessage());
            }
        }
    }

    /**
     * Получает количество активных генераций.
     */
    public int getActiveGenerations() {
        return properties.getGeneration().getMaxConcurrent() - generationSemaphore.availablePermits();
    }

    /**
     * Получает максимальное количество одновременных генераций.
     */
    public int getMaxConcurrent() {
        return properties.getGeneration().getMaxConcurrent();
    }
}
