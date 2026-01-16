package com.femsq.web.api.rest;

import com.femsq.database.service.RaFtStService;
import com.femsq.web.api.dto.RaFtStDto;
import com.femsq.web.api.mapper.RaFtStMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-контроллер для управления типами источников {@code ags.ra_ft_st}.
 */
@RestController
@RequestMapping("/api/ra/file-source-types")
public class RaFtStRestController {

    private static final Logger log = Logger.getLogger(RaFtStRestController.class.getName());

    private final RaFtStService raFtStService;
    private final RaFtStMapper raFtStMapper;

    public RaFtStRestController(RaFtStService raFtStService, RaFtStMapper raFtStMapper) {
        this.raFtStService = raFtStService;
        this.raFtStMapper = raFtStMapper;
    }

    /**
     * Возвращает все типы источников.
     */
    @GetMapping
    public List<RaFtStDto> getFileSourceTypes() {
        log.info("Handling GET /api/ra/file-source-types");
        return raFtStMapper.toDto(raFtStService.getAll());
    }
}
