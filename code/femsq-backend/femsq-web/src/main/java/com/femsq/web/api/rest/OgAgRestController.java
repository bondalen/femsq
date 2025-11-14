package com.femsq.web.api.rest;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.OgAgService;
import com.femsq.web.api.dto.OgAgCreateRequest;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgAgUpdateRequest;
import com.femsq.web.api.mapper.OgAgMapper;
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
 * REST-контроллер для управления агентскими организациями {@code ags_test.ogAg}.
 */
@RestController
@RequestMapping("/api/v1/agents")
public class OgAgRestController {

    private static final Logger log = Logger.getLogger(OgAgRestController.class.getName());

    private final OgAgService ogAgService;
    private final OgAgMapper ogAgMapper;

    public OgAgRestController(OgAgService ogAgService, OgAgMapper ogAgMapper) {
        this.ogAgService = ogAgService;
        this.ogAgMapper = ogAgMapper;
    }

    /**
     * Возвращает все агентские организации.
     */
    @GetMapping
    public List<OgAgDto> getAgents() {
        log.info("Handling GET /api/v1/agents");
        return ogAgMapper.toDto(ogAgService.getAll());
    }

    /**
     * Возвращает агентскую организацию по идентификатору.
     */
    @GetMapping("/{ogAgKey}")
    public OgAgDto getAgent(@PathVariable("ogAgKey") int ogAgKey) {
        log.info(() -> "Handling GET /api/v1/agents/" + ogAgKey);
        return ogAgService.getById(ogAgKey)
                .map(ogAgMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Агентская организация не найдена"));
    }

    /**
     * Создает новую агентскую организацию.
     */
    @PostMapping
    public ResponseEntity<OgAgDto> createAgent(@Valid @RequestBody OgAgCreateRequest request) {
        log.info("Handling POST /api/v1/agents");
        try {
            var created = ogAgService.create(ogAgMapper.toDomain(request));
            return ResponseEntity.status(HttpStatus.CREATED).body(ogAgMapper.toDto(created));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Обновляет существующую агентскую организацию.
     */
    @PutMapping("/{ogAgKey}")
    public OgAgDto updateAgent(@PathVariable("ogAgKey") int ogAgKey, @Valid @RequestBody OgAgUpdateRequest request) {
        log.info(() -> "Handling PUT /api/v1/agents/" + ogAgKey);
        try {
            var updated = ogAgService.update(ogAgMapper.toDomain(ogAgKey, request));
            return ogAgMapper.toDto(updated);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Удаляет агентскую организацию.
     */
    @DeleteMapping("/{ogAgKey}")
    public ResponseEntity<Void> deleteAgent(@PathVariable("ogAgKey") int ogAgKey) {
        log.info(() -> "Handling DELETE /api/v1/agents/" + ogAgKey);
        try {
            boolean deleted = ogAgService.delete(ogAgKey);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Агентская организация не найдена");
            }
            return ResponseEntity.noContent().build();
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}
