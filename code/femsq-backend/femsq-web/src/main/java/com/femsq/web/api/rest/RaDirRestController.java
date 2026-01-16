package com.femsq.web.api.rest;

import com.femsq.database.service.RaDirService;
import com.femsq.web.api.dto.RaDirDto;
import com.femsq.web.api.mapper.RaDirMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для управления директориями ревизий {@code ags.ra_dir}.
 */
@RestController
@RequestMapping("/api/ra/directories")
public class RaDirRestController {

    private static final Logger log = Logger.getLogger(RaDirRestController.class.getName());

    private final RaDirService raDirService;
    private final RaDirMapper raDirMapper;

    public RaDirRestController(RaDirService raDirService, RaDirMapper raDirMapper) {
        this.raDirService = raDirService;
        this.raDirMapper = raDirMapper;
    }

    /**
     * Возвращает все директории.
     */
    @GetMapping
    public List<RaDirDto> getDirectories() {
        log.info("Handling GET /api/ra/directories");
        return raDirMapper.toDto(raDirService.getAll());
    }
    
    /**
     * Возвращает директорию по идентификатору.
     */
    @GetMapping("/{id}")
    public RaDirDto getDirectoryById(@PathVariable("id") int id) {
        log.info(() -> "Handling GET /api/ra/directories/" + id);
        return raDirService.getById(id)
                .map(raDirMapper::toDto)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.NOT_FOUND, 
                        "Директория с идентификатором " + id + " не найдена"));
    }
}