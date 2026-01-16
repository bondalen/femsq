package com.femsq.web.api.rest;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RaFService;
import com.femsq.web.api.dto.RaFCreateRequest;
import com.femsq.web.api.dto.RaFDto;
import com.femsq.web.api.dto.RaFUpdateRequest;
import com.femsq.web.api.mapper.RaFMapper;
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
 * REST-контроллер для управления файлами ревизий {@code ags.ra_f}.
 */
@RestController
@RequestMapping("/api/ra")
public class RaFRestController {

    private static final Logger log = Logger.getLogger(RaFRestController.class.getName());

    private final RaFService raFService;
    private final RaFMapper raFMapper;

    public RaFRestController(RaFService raFService, RaFMapper raFMapper) {
        this.raFService = raFService;
        this.raFMapper = raFMapper;
    }

    /**
     * Возвращает все файлы.
     */
    @GetMapping("/files")
    public List<RaFDto> getFiles() {
        log.info("Handling GET /api/ra/files");
        return raFMapper.toDto(raFService.getAll());
    }

    /**
     * Возвращает файл по идентификатору.
     */
    @GetMapping("/files/{id}")
    public RaFDto getFile(@PathVariable("id") long id) {
        log.info(() -> "Handling GET /api/ra/files/" + id);
        return raFService.getById(id)
                .map(raFMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Файл не найден"));
    }

    /**
     * Возвращает файлы для указанной директории.
     */
    @GetMapping("/directories/{dirId}/files")
    public List<RaFDto> getFilesByDirId(@PathVariable("dirId") int dirId) {
        log.info(() -> "Handling GET /api/ra/directories/" + dirId + "/files");
        return raFMapper.toDto(raFService.getByDirId(dirId));
    }

    /**
     * Создает новый файл.
     */
    @PostMapping("/files")
    public ResponseEntity<RaFDto> createFile(@Valid @RequestBody RaFCreateRequest request) {
        log.info("Handling POST /api/ra/files");
        try {
            var created = raFService.create(raFMapper.toDomain(request));
            return ResponseEntity.status(HttpStatus.CREATED).body(raFMapper.toDto(created));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Обновляет существующий файл.
     */
    @PutMapping("/files/{id}")
    public RaFDto updateFile(
            @PathVariable("id") long id,
            @Valid @RequestBody RaFUpdateRequest request) {
        log.info(() -> "Handling PUT /api/ra/files/" + id);
        try {
            var updated = raFService.update(raFMapper.toDomain(id, request));
            return raFMapper.toDto(updated);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Удаляет файл.
     */
    @DeleteMapping("/files/{id}")
    public ResponseEntity<Void> deleteFile(@PathVariable("id") long id) {
        log.info(() -> "Handling DELETE /api/ra/files/" + id);
        try {
            boolean deleted = raFService.delete(id);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Файл не найден");
            }
            return ResponseEntity.noContent().build();
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}
