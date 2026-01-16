package com.femsq.web.api.rest;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RaFtService;
import com.femsq.web.api.dto.RaFtDto;
import com.femsq.web.api.mapper.RaFtMapper;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * REST контроллер для работы со справочником типов файлов {@code ags.ra_ft}.
 * Предоставляет endpoints для lookup операций в UI.
 */
@RestController
@RequestMapping("/api/ra/file-types")
public class RaFtRestController {

    private static final Logger log = Logger.getLogger(RaFtRestController.class.getName());

    private final RaFtService raFtService;
    private final RaFtMapper raFtMapper;

    public RaFtRestController(RaFtService raFtService, RaFtMapper raFtMapper) {
        this.raFtService = Objects.requireNonNull(raFtService, "raFtService");
        this.raFtMapper = Objects.requireNonNull(raFtMapper, "raFtMapper");
    }

    /**
     * Возвращает все типы файлов для использования в lookup (выпадающих списках).
     */
    @GetMapping
    public List<RaFtDto> getAllFileTypes() {
        log.info("Handling GET /api/ra/file-types");
        try {
            return raFtMapper.toDto(raFtService.getAll());
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Возвращает тип файла по идентификатору.
     */
    @GetMapping("/{id}")
    public RaFtDto getFileTypeById(@PathVariable("id") int id) {
        log.info(() -> "Handling GET /api/ra/file-types/" + id);
        try {
            return raFtService.getById(id)
                    .map(raFtMapper::toDto)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Тип файла с идентификатором " + id + " не найден"));
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}
