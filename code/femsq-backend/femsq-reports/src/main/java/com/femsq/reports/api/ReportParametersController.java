package com.femsq.reports.api;

import com.femsq.database.model.Og;
import com.femsq.database.model.OgAg;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgService;
import com.femsq.reports.core.ReportDiscoveryService;
import com.femsq.reports.model.ReportMetadata;
import com.femsq.reports.model.ReportParameter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * REST контроллер для работы со справочниками параметров отчётов.
 * 
 * <p>Предоставляет API для:
 * <ul>
 *   <li>Получения справочника контрагентов (организаций)</li>
 *   <li>Получения справочника объектов (агентских организаций)</li>
 *   <li>Динамической загрузки данных из внешних API endpoints</li>
 * </ul>
 * 
 * <p>Используется для заполнения выпадающих списков параметров отчётов,
 * когда в метаданных отчёта указан {@code source.type="api"}.
 * 
 * @author Александр
 * @version 1.0.0
 * @since 2025-11-21
 */
@RestController
@RequestMapping("/api/v1/reports/parameters")
public class ReportParametersController {

    private static final Logger log = LoggerFactory.getLogger(ReportParametersController.class);

    private final OgService ogService;
    private final OgAgService ogAgService;
    private final ReportDiscoveryService discoveryService;
    private final RestTemplate restTemplate;

    public ReportParametersController(
            OgService ogService,
            OgAgService ogAgService,
            ReportDiscoveryService discoveryService,
            RestTemplate restTemplate
    ) {
        this.ogService = ogService;
        this.ogAgService = ogAgService;
        this.discoveryService = discoveryService;
        this.restTemplate = restTemplate;
    }

    /**
     * GET /api/reports/parameters/contractors
     * Получает справочник контрагентов (организаций) для параметров отчётов.
     * 
     * <p>Возвращает список организаций в формате, подходящем для выпадающих списков:
     * <pre>{@code
     * [
     *   {"value": "1", "label": "Организация 1"},
     *   {"value": "2", "label": "Организация 2"}
     * ]
     * }</pre>
     * 
     * @return список контрагентов в формате {value, label}
     */
    @GetMapping("/contractors")
    public ResponseEntity<List<Map<String, Object>>> getContractors() {
        log.info("GET /api/reports/parameters/contractors");
        
        try {
            List<Og> organizations = ogService.getAll(0, Integer.MAX_VALUE, "ogName", "asc", null);
            
            List<Map<String, Object>> result = organizations.stream()
                    .map(org -> {
                        Map<String, Object> item = new HashMap<>();
                        item.put("value", org.ogKey());
                        String label = org.ogName() != null ? org.ogName() 
                                : (org.ogFullName() != null ? org.ogFullName() 
                                : "Организация #" + org.ogKey());
                        item.put("label", label);
                        return item;
                    })
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Failed to get contractors", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/parameters/objects
     * Получает справочник объектов (агентских организаций) для параметров отчётов.
     * 
     * <p>Возвращает список агентских организаций в формате, подходящем для выпадающих списков:
     * <pre>{@code
     * [
     *   {"value": "1", "label": "Агентская организация 1"},
     *   {"value": "2", "label": "Агентская организация 2"}
     * ]
     * }</pre>
     * 
     * @return список объектов в формате {value, label}
     */
    @GetMapping("/objects")
    public ResponseEntity<List<Map<String, Object>>> getObjects() {
        log.info("GET /api/reports/parameters/objects");
        
        try {
            List<OgAg> agents = ogAgService.getAll();
            
            List<Map<String, Object>> result = agents.stream()
                    .map(agent -> {
                        Map<String, Object> item = new HashMap<>();
                        item.put("value", agent.ogAgKey());
                        String label = agent.code() != null ? agent.code() 
                                : "Агентская организация #" + agent.ogAgKey();
                        item.put("label", label);
                        return item;
                    })
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Failed to get objects", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/reports/parameters/source/{reportId}/{parameterName}
     * Динамически загружает данные для параметра отчёта из внешнего API.
     * 
     * <p>Используется, когда в метаданных отчёта указан {@code source.type="api"}.
     * Загружает данные из указанного endpoint и преобразует их в формат {value, label}.
     * 
     * @param reportId      идентификатор отчёта
     * @param parameterName имя параметра
     * @return список опций в формате {value, label}
     */
    @GetMapping("/source/{reportId}/{parameterName}")
    public ResponseEntity<List<Map<String, Object>>> getParameterSource(
            @PathVariable String reportId,
            @PathVariable String parameterName
    ) {
        log.info("GET /api/reports/parameters/source/{}/{}", reportId, parameterName);
        
        try {
            // Получаем метаданные отчёта
            ReportMetadata metadata = discoveryService.getMetadata(reportId);
            if (metadata == null) {
                return ResponseEntity.notFound().build();
            }
            
            // Находим параметр
            ReportParameter parameter = metadata.parameters().stream()
                    .filter(p -> p.name().equals(parameterName))
                    .findFirst()
                    .orElse(null);
            
            if (parameter == null) {
                return ResponseEntity.notFound().build();
            }
            
            // Проверяем наличие source
            if (parameter.source() == null || !"api".equals(parameter.source().type())) {
                return ResponseEntity.badRequest().build();
            }
            
            ReportParameter.Source source = parameter.source();
            
            // Загружаем данные из внешнего API
            List<Map<String, Object>> options = loadOptionsFromApi(
                    source.endpoint(),
                    source.valueField(),
                    source.labelField()
            );
            
            return ResponseEntity.ok(options);
            
        } catch (Exception e) {
            log.error("Failed to load parameter source for report: {}, parameter: {}", 
                    reportId, parameterName, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Загружает опции из внешнего API endpoint.
     * 
     * @param endpoint  URL endpoint для загрузки данных
     * @param valueField имя поля в ответе, содержащего значение
     * @param labelField имя поля в ответе, содержащего отображаемое имя
     * @return список опций в формате {value, label}
     */
    private List<Map<String, Object>> loadOptionsFromApi(
            String endpoint,
            String valueField,
            String labelField
    ) {
        try {
            // Загружаем данные из API
            Object response = restTemplate.getForObject(endpoint, Object.class);
            
            // Преобразуем ответ в список опций
            List<Map<String, Object>> options = new ArrayList<>();
            
            if (response instanceof List<?> list) {
                // Если ответ - список объектов
                for (Object item : list) {
                    if (item instanceof Map<?, ?> map) {
                        Map<String, Object> option = new HashMap<>();
                        Object value = map.get(valueField);
                        Object label = map.get(labelField);
                        
                        option.put("value", value != null ? value.toString() : "");
                        option.put("label", label != null ? label.toString() : "");
                        options.add(option);
                    }
                }
            } else if (response instanceof Map<?, ?> map) {
                // Если ответ - один объект, оборачиваем в список
                Map<String, Object> option = new HashMap<>();
                Object value = map.get(valueField);
                Object label = map.get(labelField);
                
                option.put("value", value != null ? value.toString() : "");
                option.put("label", label != null ? label.toString() : "");
                options.add(option);
            }
            
            return options;
            
        } catch (RestClientException e) {
            log.error("Failed to load options from API endpoint: {}", endpoint, e);
            return List.of();
        }
    }
}
