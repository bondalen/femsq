package com.femsq.web.api.rest;

import com.femsq.database.service.RaFtSnService;
import com.femsq.web.api.dto.RaFtSnDto;
import com.femsq.web.api.mapper.RaFtSnMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-контроллер для управления именами источников {@code ags.ra_ft_sn}.
 */
@RestController
@RequestMapping("/api/ra/file-source-names")
public class RaFtSnRestController {

    private static final Logger log = Logger.getLogger(RaFtSnRestController.class.getName());

    private final RaFtSnService raFtSnService;
    private final RaFtSnMapper raFtSnMapper;

    public RaFtSnRestController(RaFtSnService raFtSnService, RaFtSnMapper raFtSnMapper) {
        this.raFtSnService = raFtSnService;
        this.raFtSnMapper = raFtSnMapper;
    }

    /**
     * Возвращает все имена источников.
     */
    @GetMapping
    public List<RaFtSnDto> getFileSourceNames() {
        log.info("Handling GET /api/ra/file-source-names");
        return raFtSnMapper.toDto(raFtSnService.getAll());
    }
}
