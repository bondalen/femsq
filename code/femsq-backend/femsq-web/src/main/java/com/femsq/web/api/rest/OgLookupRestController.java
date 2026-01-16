package com.femsq.web.api.rest;

import com.femsq.database.service.OgService;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.mapper.OgMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для lookup операций с организациями.
 * Предоставляет упрощенный API на пути /api/og для использования во frontend.
 */
@RestController
@RequestMapping("/api/og")
public class OgLookupRestController {

    private static final Logger log = Logger.getLogger(OgLookupRestController.class.getName());

    private final OgService ogService;
    private final OgMapper ogMapper;

    public OgLookupRestController(OgService ogService, OgMapper ogMapper) {
        this.ogService = ogService;
        this.ogMapper = ogMapper;
    }

    /**
     * Возвращает все организации без пагинации (для lookup).
     */
    @GetMapping
    public List<OgDto> getAllOrganizations() {
        log.info("Handling GET /api/og (lookup)");
        // Используем большой размер страницы для получения всех организаций
        return ogMapper.toDto(ogService.getAll(0, 10000, "ogNm", "asc", null));
    }

    /**
     * Возвращает организацию по идентификатору.
     */
    @GetMapping("/{id}")
    public OgDto getOrganizationById(@PathVariable("id") int id) {
        log.info(() -> "Handling GET /api/og/" + id);
        return ogService.getById(id)
                .map(ogMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, 
                        "Организация с идентификатором " + id + " не найдена"));
    }
}
