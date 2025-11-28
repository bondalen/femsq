package com.femsq.reports.core;

import com.femsq.reports.config.ReportsProperties;
import com.femsq.reports.model.ReportInfo;
import com.femsq.reports.model.ReportMetadata;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

/**
 * Сервис обнаружения и сканирования отчётов.
 * 
 * <p>Сканирует директории с отчётами, загружает метаданные и кэширует их.
 * Поддерживает hot-reload через @Scheduled метод.
 * 
 * <p>Приоритет загрузки:
 * <ol>
 *   <li>Внешние отчёты из ./reports/custom/ и ./reports/templates/</li>
 *   <li>Встроенные отчёты из classpath:reports/embedded/</li>
 * </ol>
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@Service
public class ReportDiscoveryService {

    private static final Logger log = LoggerFactory.getLogger(ReportDiscoveryService.class);

    private final ReportsProperties properties;
    private final ReportMetadataLoader metadataLoader;
    private final ResourceLoader resourceLoader;

    /**
     * Кэш метаданных отчётов.
     * Key: reportId, Value: ReportMetadata
     */
    private final Map<String, ReportMetadata> metadataCache = new ConcurrentHashMap<>();

    /**
     * Время последнего обновления кэша.
     */
    private volatile long lastUpdateTime = 0;

    public ReportDiscoveryService(
            ReportsProperties properties,
            ReportMetadataLoader metadataLoader,
            ResourceLoader resourceLoader
    ) {
        this.properties = properties;
        this.metadataLoader = metadataLoader;
        this.resourceLoader = resourceLoader;
    }

    /**
     * Инициализация при старте приложения.
     * Выполняет первичное сканирование отчётов.
     */
    @PostConstruct
    public void initialize() {
        log.info("Initializing ReportDiscoveryService...");
        scanReports();
    }

    /**
     * Сканирует все доступные отчёты и обновляет кэш.
     * 
     * <p>Вызывается автоматически при старте приложения и по расписанию.
     */
    public void scanReports() {
        log.info("Starting reports scan...");
        long startTime = System.currentTimeMillis();

        Map<String, ReportMetadata> newCache = new ConcurrentHashMap<>();

        // 1. Сканируем внешние отчёты (приоритет)
        if (properties.getExternal().isEnabled()) {
            scanExternalReports(newCache);
        }

        // 2. Загружаем встроенные отчёты (fallback)
        if (properties.getEmbedded().isEnabled()) {
            scanEmbeddedReports(newCache);
        }

        // Обновляем кэш атомарно
        metadataCache.clear();
        metadataCache.putAll(newCache);
        lastUpdateTime = System.currentTimeMillis();

        long duration = lastUpdateTime - startTime;
        log.info("Reports scan completed: found {} reports in {}ms", 
                metadataCache.size(), duration);
    }

    /**
     * Сканирует внешние отчёты из файловой системы.
     * 
     * @param cache кэш для добавления найденных отчётов
     */
    private void scanExternalReports(Map<String, ReportMetadata> cache) {
        Path externalPath = properties.getExternal().getPathAsPath();
        
        if (!Files.exists(externalPath)) {
            log.debug("External reports directory does not exist: {}", externalPath);
            return;
        }

        // Сканируем custom/ и templates/ поддиректории
        List<Path> directoriesToScan = List.of(
                externalPath.resolve("custom"),
                externalPath.resolve("templates")
        );

        for (Path directory : directoriesToScan) {
            if (!Files.exists(directory) || !Files.isDirectory(directory)) {
                log.debug("Skipping non-existent directory: {}", directory);
                continue;
            }

            try (Stream<Path> files = Files.walk(directory, 1)) {
                files
                        .filter(Files::isRegularFile)
                        .filter(p -> {
                            String fileName = p.getFileName().toString().toLowerCase();
                            return fileName.endsWith(".jrxml") || fileName.endsWith(".jasper");
                        })
                        .forEach(jrxmlFile -> {
                            try {
                                ReportMetadata metadata = metadataLoader.loadMetadata(jrxmlFile);
                                if (metadata != null) {
                                    // Внешние отчёты имеют приоритет (перезаписывают встроенные)
                                    ReportMetadata existing = cache.put(metadata.id(), metadata);
                                    if (existing != null) {
                                        log.debug("Overwriting report {} with external version from {}", 
                                                metadata.id(), jrxmlFile);
                                    } else {
                                        log.debug("Loaded external report: {} from {}", 
                                                metadata.id(), jrxmlFile);
                                    }
                                } else {
                                    log.warn("Failed to load metadata for report file: {}", jrxmlFile);
                                }
                            } catch (Exception e) {
                                log.error("Error loading report from: {}", jrxmlFile, e);
                            }
                        });
            } catch (IOException e) {
                log.error("Failed to scan directory: {}", directory, e);
            }
        }
    }

    /**
     * Сканирует встроенные отчёты из classpath.
     * 
     * <p>Встроенные отчёты добавляются только если внешний отчёт
     * с таким же ID не найден (fallback механизм).
     * 
     * @param cache кэш для добавления найденных отчётов (только если нет внешнего)
     */
    private void scanEmbeddedReports(Map<String, ReportMetadata> cache) {
        String embeddedPath = properties.getEmbedded().getPath();
        
        try {
            // Убираем префикс "classpath:" если есть
            String resourcePath = embeddedPath.startsWith("classpath:") 
                    ? embeddedPath.substring(10) 
                    : embeddedPath;
            
            // Убираем ведущий слеш
            if (resourcePath.startsWith("/")) {
                resourcePath = resourcePath.substring(1);
            }

            // Убираем завершающий слеш
            if (resourcePath.endsWith("/")) {
                resourcePath = resourcePath.substring(0, resourcePath.length() - 1);
            }

            // Загружаем metadata.json для получения списка встроенных отчётов
            String metadataJsonPath = resourcePath + "/metadata.json";
            Resource metadataResource = resourceLoader.getResource("classpath:" + metadataJsonPath);
            
            if (!metadataResource.exists()) {
                log.warn("Embedded reports metadata.json not found: {}", metadataJsonPath);
                return;
            }

            // Парсим metadata.json и загружаем каждый отчёт
            try (InputStream is = metadataResource.getInputStream()) {
                com.fasterxml.jackson.databind.ObjectMapper mapper = 
                        new com.fasterxml.jackson.databind.ObjectMapper();
                com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(is);
                com.fasterxml.jackson.databind.JsonNode reportsNode = root.get("reports");
                
                if (reportsNode != null && reportsNode.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode reportNode : reportsNode) {
                        String reportId = reportNode.get("id").asText();
                        
                        // Пропускаем, если уже есть внешний отчёт с таким ID
                        if (cache.containsKey(reportId)) {
                            log.debug("Skipping embedded report {} (external version exists)", reportId);
                            continue;
                        }
                        
                        // Загружаем метаданные отчёта из JSON файла
                        String reportJsonPath = resourcePath + "/" + reportId + ".json";
                        Resource reportJsonResource = resourceLoader.getResource("classpath:" + reportJsonPath);
                        
                        if (reportJsonResource.exists()) {
                            try (InputStream jsonIs = reportJsonResource.getInputStream()) {
                                ReportMetadata metadata = metadataLoader.loadFromJson(jsonIs, reportId);
                                if (metadata != null) {
                                    cache.put(reportId, metadata);
                                    log.debug("Loaded embedded report: {}", reportId);
                                } else {
                                    log.warn("Failed to load metadata for embedded report: {}", reportId);
                                }
                            }
                        } else {
                            log.warn("JSON metadata not found for embedded report: {}", reportJsonPath);
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            log.error("Failed to scan embedded reports from: {}", embeddedPath, e);
        }
    }
    

    /**
     * Получает список всех доступных отчётов.
     * 
     * @return список ReportInfo для всех отчётов
     */
    public List<ReportInfo> getAllReports() {
        return metadataCache.values().stream()
                .map(this::toReportInfo)
                .sorted((a, b) -> a.name().compareToIgnoreCase(b.name()))
                .toList();
    }

    /**
     * Получает список отчётов с фильтрацией.
     * 
     * @param category категория для фильтрации (null = все категории)
     * @param tag      тег для фильтрации (null = все теги)
     * @return отфильтрованный список отчётов
     */
    public List<ReportInfo> getReports(String category, String tag) {
        return metadataCache.values().stream()
                .filter(metadata -> category == null || 
                        (metadata.category() != null && metadata.category().equals(category)))
                .filter(metadata -> tag == null || 
                        (metadata.tags() != null && metadata.tags().contains(tag)))
                .map(this::toReportInfo)
                .sorted((a, b) -> a.name().compareToIgnoreCase(b.name()))
                .toList();
    }

    /**
     * Получает метаданные конкретного отчёта.
     * 
     * @param reportId идентификатор отчёта
     * @return ReportMetadata или null если не найден
     */
    public ReportMetadata getMetadata(String reportId) {
        return metadataCache.get(reportId);
    }

    /**
     * Проверяет существование отчёта.
     * 
     * @param reportId идентификатор отчёта
     * @return true если отчёт найден
     */
    public boolean reportExists(String reportId) {
        return metadataCache.containsKey(reportId);
    }

    /**
     * Получает время последнего обновления кэша.
     * 
     * @return timestamp последнего обновления
     */
    public long getLastUpdateTime() {
        return lastUpdateTime;
    }

    /**
     * Получает количество отчётов в кэше.
     * 
     * @return количество отчётов
     */
    public int getReportCount() {
        return metadataCache.size();
    }

    /**
     * Получает список всех уникальных категорий отчётов.
     * 
     * @return отсортированный список категорий
     */
    public List<String> getAllCategories() {
        return metadataCache.values().stream()
                .map(ReportMetadata::category)
                .filter(category -> category != null && !category.isBlank())
                .distinct()
                .sorted()
                .toList();
    }

    /**
     * Получает список всех уникальных тегов отчётов.
     * 
     * @return отсортированный список тегов
     */
    public List<String> getAllTags() {
        return metadataCache.values().stream()
                .map(ReportMetadata::tags)
                .filter(tags -> tags != null && !tags.isEmpty())
                .flatMap(List::stream)
                .distinct()
                .sorted()
                .toList();
    }

    /**
     * Автоматическое обновление списка отчётов по расписанию.
     * 
     * <p>Вызывается с интервалом из конфигурации (по умолчанию 60000ms)
     * для обнаружения новых отчётов и обновления метаданных существующих.
     */
    @Scheduled(fixedDelay = 60000) // Будет переопределено через SpEL если нужно
    public void scheduledScan() {
        // Используем значение из конфигурации
        long scanInterval = properties.getExternal().getScanInterval();
        
        // Если сканирование отключено или интервал = 0, пропускаем
        if (!properties.getExternal().isEnabled() || scanInterval <= 0) {
            return;
        }

        log.debug("Scheduled reports scan triggered (interval: {}ms)", scanInterval);
        scanReports();
    }

    // Private helper methods

    /**
     * Преобразует ReportMetadata в ReportInfo.
     * 
     * @param metadata метаданные отчёта
     * @return ReportInfo для списка
     */
    private ReportInfo toReportInfo(ReportMetadata metadata) {
        // Определяем источник отчёта
        String source = determineSource(metadata);
        
        return new ReportInfo(
                metadata.id(),
                metadata.name(),
                metadata.description(),
                metadata.category(),
                metadata.tags() != null ? metadata.tags() : List.of(),
                source,
                metadata.files().thumbnail()
        );
    }

    /**
     * Определяет источник отчёта (embedded или external).
     * 
     * @param metadata метаданные отчёта
     * @return "embedded" или "external"
     */
    private String determineSource(ReportMetadata metadata) {
        // Простая эвристика: если файл находится в external директории - external
        // Иначе - embedded
        Path externalPath = properties.getExternal().getPathAsPath();
        Path templatePath = externalPath.resolve(metadata.files().template());
        
        if (Files.exists(templatePath)) {
            return "external";
        }
        
        return "embedded";
    }
}
