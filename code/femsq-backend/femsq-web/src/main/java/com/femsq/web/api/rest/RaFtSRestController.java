package com.femsq.web.api.rest;

import com.femsq.database.service.RaFtSService;
import com.femsq.web.api.dto.RaFtSDto;
import com.femsq.web.api.mapper.RaFtSMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-контроллер для управления источниками/листами {@code ags.ra_ft_s}.
 */
@RestController
@RequestMapping("/api/ra/file-sources")
public class RaFtSRestController {

    private static final Logger log = Logger.getLogger(RaFtSRestController.class.getName());

    private final RaFtSService raFtSService;
    private final RaFtSMapper raFtSMapper;

    public RaFtSRestController(RaFtSService raFtSService, RaFtSMapper raFtSMapper) {
        this.raFtSService = raFtSService;
        this.raFtSMapper = raFtSMapper;
    }

    /**
     * Возвращает все источники/листы.
     */
    @GetMapping
    public List<RaFtSDto> getFileSources() {
        log.info("Handling GET /api/ra/file-sources");
        return raFtSMapper.toDto(raFtSService.getAll());
    }
}
