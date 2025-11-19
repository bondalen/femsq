package com.femsq.web.api.rest;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgService;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgCreateRequest;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.dto.OgUpdateRequest;
import com.femsq.web.api.dto.PageResponse;
import com.femsq.web.api.mapper.OgAgMapper;
import com.femsq.web.api.mapper.OgMapper;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для управления организациями {@code ags_test.og}.
 */
@RestController
@RequestMapping("/api/v1/organizations")
public class OgRestController {

    private static final Logger log = Logger.getLogger(OgRestController.class.getName());

    private final OgService ogService;
    private final OgAgService ogAgService;
    private final OgMapper ogMapper;
    private final OgAgMapper ogAgMapper;

    public OgRestController(OgService ogService, OgAgService ogAgService, OgMapper ogMapper, OgAgMapper ogAgMapper) {
        this.ogService = ogService;
        this.ogAgService = ogAgService;
        this.ogMapper = ogMapper;
        this.ogAgMapper = ogAgMapper;
    }

    /**
     * Возвращает список организаций с поддержкой пагинации и сортировки.
     * По умолчанию возвращает первую страницу с 10 записями.
     *
     * @param page номер страницы (начиная с 0), опционально, по умолчанию 0
     * @param size размер страницы, опционально, по умолчанию 10
     * @param sort строка сортировки в формате "field,direction" (например, "ogNm,asc"), опционально
     * @return объект с пагинацией
     */
    @GetMapping
    public PageResponse<OgDto> getOrganizations(
            @RequestParam(required = false, defaultValue = "0") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false) String ogName) {
        log.info(() -> String.format("Handling GET /api/v1/organizations?page=%s&size=%s&sort=%s&ogName=%s", page, size, sort, ogName));
        
        int pageNum = Math.max(0, page != null ? page : 0);
        int pageSize = size != null && size > 0 ? size : 10;
        
        String sortField = "ogKey";
        String sortDirection = "asc";
        if (sort != null && !sort.trim().isEmpty()) {
            String[] sortParts = sort.split(",");
            if (sortParts.length > 0) {
                sortField = sortParts[0].trim();
            }
            if (sortParts.length > 1) {
                sortDirection = sortParts[1].trim();
            }
        }

        String nameFilter = ogName != null ? ogName.trim() : null;
        if (nameFilter != null && nameFilter.isEmpty()) {
            nameFilter = null;
        }
        
        List<OgDto> content = ogMapper.toDto(ogService.getAll(pageNum, pageSize, sortField, sortDirection, nameFilter));
        long totalElements = ogService.count(nameFilter);
        
        return PageResponse.of(content, pageNum, pageSize, (int) totalElements);
    }

    /**
     * Возвращает организацию по идентификатору.
     */
    @GetMapping("/{ogKey}")
    public OgDto getOrganization(@PathVariable("ogKey") int ogKey) {
        log.info(() -> "Handling GET /api/v1/organizations/" + ogKey);
        return ogService.getById(ogKey)
                .map(ogMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Организация не найдена"));
    }

    /**
     * Возвращает агентские организации базовой организации.
     */
    @GetMapping("/{ogKey}/agents")
    public List<OgAgDto> getOrganizationAgents(@PathVariable("ogKey") int ogKey) {
        log.info(() -> "Handling GET /api/v1/organizations/" + ogKey + "/agents");
        return ogAgMapper.toDto(ogAgService.getForOrganization(ogKey));
    }

    /**
     * Создает новую организацию.
     */
    @PostMapping
    public ResponseEntity<OgDto> createOrganization(@Valid @RequestBody OgCreateRequest request) {
        log.info("Handling POST /api/v1/organizations");
        try {
            var created = ogService.create(ogMapper.toDomain(request));
            return ResponseEntity.status(HttpStatus.CREATED).body(ogMapper.toDto(created));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Обновляет существующую организацию.
     */
    @PutMapping("/{ogKey}")
    public OgDto updateOrganization(@PathVariable("ogKey") int ogKey, @Valid @RequestBody OgUpdateRequest request) {
        log.info(() -> "Handling PUT /api/v1/organizations/" + ogKey);
        try {
            var updated = ogService.update(ogMapper.toDomain(ogKey, request));
            return ogMapper.toDto(updated);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    /**
     * Удаляет организацию.
     */
    @DeleteMapping("/{ogKey}")
    public ResponseEntity<Void> deleteOrganization(@PathVariable("ogKey") int ogKey) {
        log.info(() -> "Handling DELETE /api/v1/organizations/" + ogKey);
        try {
            boolean deleted = ogService.delete(ogKey);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Организация не найдена");
            }
            return ResponseEntity.noContent().build();
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}
