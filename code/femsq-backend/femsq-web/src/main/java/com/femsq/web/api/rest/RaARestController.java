package com.femsq.web.api.rest;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RaAService;
import com.femsq.web.api.dto.RaACreateRequest;
import com.femsq.web.api.dto.RaADto;
import com.femsq.web.api.dto.RaAUpdateRequest;
import com.femsq.web.api.mapper.RaAMapper;
import jakarta.validation.Valid;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для управления ревизиями {@code ags.ra_a}.
 */
@RestController
@RequestMapping("/api/ra/audits")
public class RaARestController {

    private static final Logger log = Logger.getLogger(RaARestController.class.getName());

    private final RaAService raAService;
    private final RaAMapper raAMapper;

    public RaARestController(RaAService raAService, RaAMapper raAMapper) {
        this.raAService = raAService;
        this.raAMapper = raAMapper;
    }

    /**
     * Возвращает все ревизии.
     */
    @GetMapping
    public List<RaADto> getAudits() {
        log.info("Handling GET /api/ra/audits");
        return raAMapper.toDto(raAService.getAll());
    }

    /**
     * Возвращает ревизию по идентификатору.
     */
    @GetMapping("/{id}")
    public RaADto getAudit(@PathVariable("id") long id) {
        log.info(() -> "Handling GET /api/ra/audits/" + id);
        return raAService.getById(id)
                .map(raAMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Ревизия не найдена"));
    }

    /**
     * Создает новую ревизию.
     */
    @PostMapping
    public ResponseEntity<RaADto> createAudit(@Valid @RequestBody RaACreateRequest request) {
        log.info("Handling POST /api/ra/audits");
        try {
            var created = raAService.create(raAMapper.toDomain(request));
            return ResponseEntity.status(HttpStatus.CREATED).body(raAMapper.toDto(created));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Обновляет существующую ревизию.
     */
    @PutMapping("/{id}")
    public RaADto updateAudit(@PathVariable("id") long id, @Valid @RequestBody RaAUpdateRequest request) {
        log.info(() -> "Handling PUT /api/ra/audits/" + id);
        try {
            var updated = raAService.update(raAMapper.toDomain(id, request));
            return raAMapper.toDto(updated);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Удаляет ревизию.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAudit(@PathVariable("id") long id) {
        log.info(() -> "Handling DELETE /api/ra/audits/" + id);
        try {
            boolean deleted = raAService.delete(id);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Ревизия не найдена");
            }
            return ResponseEntity.noContent().build();
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}