package com.femsq.reports.api;

import com.femsq.reports.core.ReportDiscoveryService;
import com.femsq.reports.core.ReportGenerationService;
import com.femsq.reports.core.ReportMetadataLoader;
import com.femsq.reports.model.*;
import net.sf.jasperreports.engine.JRException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.TimeoutException;

/**
 * REST контроллер для работы с отчётами.
 * 
 * <p>Предоставляет API для:
 * <ul>
 *   <li>Получения списка доступных отчётов</li>
 *   <li>Получения метаданных отчётов</li>
 *   <li>Получения параметров отчётов с значениями по умолчанию</li>
 *   <li>Генерации отчётов в различных форматах</li>
 *   <li>Предпросмотра отчётов</li>
 * </ul>
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private static final Logger log = LoggerFactory.getLogger(ReportController.class);

    private final ReportDiscoveryService discoveryService;
    private final ReportGenerationService generationService;
    private final ReportMetadataLoader metadataLoader;

    public ReportController(
            ReportDiscoveryService discoveryService,
            ReportGenerationService generationService,
            ReportMetadataLoader metadataLoader
    ) {
        this.discoveryService = discoveryService;
        this.generationService = generationService;
        this.metadataLoader = metadataLoader;
    }

    /**
     * GET /api/reports/available
     * Получает список всех доступных отчётов.
     * 
     * @param category опциональный фильтр по категории
     * @param tag      опциональный фильтр по тегу
     * @return список отчётов
     */
    @GetMapping("/available")
    public ResponseEntity<List<ReportInfo>> getAvailableReports(
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "tag", required = false) String tag
    ) {
        log.info("GET /api/reports/available?category={}&tag={}", category, tag);
        
        try {
            List<ReportInfo> reports;
            if (category != null || tag != null) {
                reports = discoveryService.getReports(category, tag);
            } else {
                reports = discoveryService.getAllReports();
            }
            
            return ResponseEntity.ok(reports);
        } catch (Exception e) {
            log.error("Failed to get available reports", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/{reportId}/metadata
     * Получает полные метаданные отчёта.
     * 
     * @param reportId идентификатор отчёта
     * @return метаданные отчёта
     */
    @GetMapping("/{reportId}/metadata")
    public ResponseEntity<ReportMetadata> getReportMetadata(@PathVariable String reportId) {
        log.info("GET /api/reports/{}/metadata", reportId);
        
        try {
            ReportMetadata metadata = discoveryService.getMetadata(reportId);
            
            if (metadata == null) {
                return ResponseEntity.notFound().build();
            }
            
            return ResponseEntity.ok(metadata);
        } catch (Exception e) {
            log.error("Failed to get report metadata for: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/{reportId}/parameters
     * Получает параметры отчёта с разрешёнными значениями по умолчанию.
     * 
     * @param reportId идентификатор отчёта
     * @param context  опциональный контекст для разрешения динамических значений (например, contractorId)
     * @return список параметров с разрешёнными значениями по умолчанию
     */
    @GetMapping("/{reportId}/parameters")
    public ResponseEntity<List<ReportParameter>> getReportParameters(
            @PathVariable String reportId,
            @RequestParam(required = false) Map<String, String> context
    ) {
        log.info("GET /api/reports/{}/parameters?context={}", reportId, context);
        
        try {
            ReportMetadata metadata = discoveryService.getMetadata(reportId);
            
            if (metadata == null) {
                return ResponseEntity.notFound().build();
            }
            
            List<ReportParameter> parameters = metadata.parameters();
            
            if (parameters == null || parameters.isEmpty()) {
                return ResponseEntity.ok(List.of());
            }
            
            // Разрешаем динамические значения по умолчанию
            Map<String, String> contextMap = context != null ? context : new HashMap<>();
            List<ReportParameter> resolvedParameters = metadataLoader.resolveDefaultValues(
                    parameters, 
                    contextMap
            );
            
            return ResponseEntity.ok(resolvedParameters);
        } catch (Exception e) {
            log.error("Failed to get report parameters for: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/reports/{reportId}/generate
     * Генерирует отчёт в указанном формате.
     * 
     * @param reportId идентификатор отчёта
     * @param request  запрос на генерацию (параметры и формат)
     * @return сгенерированный отчёт в виде файла
     */
    @PostMapping("/{reportId}/generate")
    public ResponseEntity<byte[]> generateReport(
            @PathVariable String reportId,
            @RequestBody ReportGenerationRequest request
    ) {
        log.info("POST /api/reports/{}/generate, format={}", reportId, request.format());
        
        try {
            // Проверяем, что reportId в пути совпадает с reportId в запросе
            if (!reportId.equals(request.reportId())) {
                return ResponseEntity.badRequest().build();
            }
            
            // Проверяем валидность формата
            if (!request.isValidFormat()) {
                return ResponseEntity.badRequest().build();
            }
            
            // Генерируем отчёт
            ReportResult result = generationService.generateReport(request);
            
            // Настраиваем HTTP заголовки
            HttpHeaders headers = new HttpHeaders();
            String mimeType = Objects.requireNonNull(result.getMimeType(), "MIME type cannot be null");
            String fileName = Objects.requireNonNull(result.fileName(), "File name cannot be null");
            headers.setContentType(MediaType.parseMediaType(mimeType));
            headers.setContentDispositionFormData("attachment", fileName);
            headers.setContentLength(result.size());
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(result.content());
                    
        } catch (IllegalArgumentException e) {
            log.error("Invalid request for report generation: {}", e.getMessage(), e);
            return ResponseEntity.badRequest().build();
        } catch (TimeoutException e) {
            log.warn("Report generation timeout: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.REQUEST_TIMEOUT).build();
        } catch (JRException e) {
            log.error("Failed to generate report: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        } catch (Exception e) {
            log.error("Unexpected error during report generation: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/reports/{reportId}/preview
     * Генерирует предпросмотр отчёта (первая страница в PDF).
     * 
     * @param reportId   идентификатор отчёта
     * @param parameters параметры отчёта
     * @return предпросмотр отчёта в PDF формате
     */
    @PostMapping("/{reportId}/preview")
    public ResponseEntity<byte[]> generatePreview(
            @PathVariable String reportId,
            @RequestBody(required = false) Map<String, Object> parameters
    ) {
        log.info("POST /api/reports/{}/preview", reportId);
        
        try {
            // Генерируем preview
            ReportResult result = generationService.generatePreview(
                    reportId, 
                    parameters != null ? parameters : Map.of()
            );
            
            // Настраиваем HTTP заголовки
            HttpHeaders headers = new HttpHeaders();
            String fileName = Objects.requireNonNull(result.fileName(), "File name cannot be null");
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("inline", fileName);
            headers.setContentLength(result.size());
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(result.content());
                    
        } catch (IllegalArgumentException e) {
            log.warn("Invalid request for report preview: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (JRException e) {
            log.error("Failed to generate report preview: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        } catch (Exception e) {
            log.error("Unexpected error during report preview generation: {}", reportId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/categories
     * Получает список всех категорий отчётов.
     * 
     * @return список категорий
     */
    @GetMapping("/categories")
    public ResponseEntity<List<String>> getCategories() {
        log.info("GET /api/reports/categories");
        
        try {
            List<String> categories = discoveryService.getAllCategories();
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            log.error("Failed to get categories", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/tags
     * Получает список всех тегов отчётов.
     * 
     * @return список тегов
     */
    @GetMapping("/tags")
    public ResponseEntity<List<String>> getTags() {
        log.info("GET /api/reports/tags");
        
        try {
            List<String> tags = discoveryService.getAllTags();
            return ResponseEntity.ok(tags);
        } catch (Exception e) {
            log.error("Failed to get tags", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
