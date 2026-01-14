package com.femsq.web.api.rest;

import com.femsq.database.service.RaAtService;
import com.femsq.web.api.dto.RaAtDto;
import com.femsq.web.api.mapper.RaAtMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-контроллер для управления типами ревизий {@code ags.ra_at}.
 */
@RestController
@RequestMapping("/api/ra/audit-types")
public class RaAtRestController {

    private static final Logger log = Logger.getLogger(RaAtRestController.class.getName());

    private final RaAtService raAtService;
    private final RaAtMapper raAtMapper;

    public RaAtRestController(RaAtService raAtService, RaAtMapper raAtMapper) {
        this.raAtService = raAtService;
        this.raAtMapper = raAtMapper;
    }

    /**
     * Возвращает все типы ревизий.
     */
    @GetMapping
    public List<RaAtDto> getAuditTypes() {
        log.info("Handling GET /api/ra/audit-types");
        return raAtMapper.toDto(raAtService.getAll());
    }
}