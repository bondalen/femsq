package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaAtService;
import com.femsq.database.service.RaDirService;
import com.femsq.web.api.dto.AuditExecutionResult;
import com.femsq.web.api.dto.RaACreateRequest;
import com.femsq.web.api.dto.RaADto;
import com.femsq.web.api.dto.RaAUpdateRequest;
import com.femsq.web.api.dto.RaAtDto;
import com.femsq.web.api.dto.RaDirDto;
import com.femsq.web.api.mapper.RaAMapper;
import com.femsq.web.api.mapper.RaAtMapper;
import com.femsq.web.api.mapper.RaDirMapper;
import com.femsq.web.audit.AuditExecutionService;
import com.femsq.web.audit.runtime.AuditExecutionRegistry;
import java.util.List;
import java.util.Optional;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер домена ревизий (ra_a/ra_at/ra_dir).
 *
 * <p>Реализует:</p>
 * <ul>
 *   <li>Query: {@code audits}, {@code audit}, {@code auditTypes}, {@code directories}</li>
 *   <li>Mutation: {@code createAudit}, {@code updateAudit}, {@code deleteAudit}, {@code executeAudit}</li>
 *   <li>SchemaMapping (lazy): {@code Audit.directory}, {@code Audit.auditType}</li>
 * </ul>
 */
@Controller
public class RaAGraphqlController {

    private static final Logger log = Logger.getLogger(RaAGraphqlController.class.getName());

    private final RaAService raAService;
    private final RaAtService raAtService;
    private final RaDirService raDirService;
    private final RaAMapper raAMapper;
    private final RaAtMapper raAtMapper;
    private final RaDirMapper raDirMapper;
    private final AuditExecutionService auditExecutionService;
    private final AuditExecutionRegistry auditExecutionRegistry;

    public RaAGraphqlController(
            RaAService raAService,
            RaAtService raAtService,
            RaDirService raDirService,
            RaAMapper raAMapper,
            RaAtMapper raAtMapper,
            RaDirMapper raDirMapper,
            AuditExecutionService auditExecutionService,
            AuditExecutionRegistry auditExecutionRegistry) {
        this.raAService = raAService;
        this.raAtService = raAtService;
        this.raDirService = raDirService;
        this.raAMapper = raAMapper;
        this.raAtMapper = raAtMapper;
        this.raDirMapper = raDirMapper;
        this.auditExecutionService = auditExecutionService;
        this.auditExecutionRegistry = auditExecutionRegistry;
    }

    @QueryMapping
    public List<RaADto> audits() {
        log.info("GraphQL query audits");
        try {
            return raAMapper.toDto(raAService.getAll());
        } catch (MissingConfigurationException exception) {
            log.warning("Database configuration is missing: " + exception.getMessage());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        }
    }

    @QueryMapping
    public RaADto audit(@Argument("id") int id) {
        log.info(() -> "GraphQL query audit id=" + id);
        Optional<RaADto> audit = raAService.getById(id).map(raAMapper::toDto);
        return audit.orElse(null);
    }

    @QueryMapping
    public List<RaAtDto> auditTypes() {
        log.info("GraphQL query auditTypes");
        return raAtMapper.toDto(raAtService.getAll());
    }

    @QueryMapping
    public List<RaDirDto> directories() {
        log.info("GraphQL query directories");
        return raDirMapper.toDto(raDirService.getAll());
    }

    @MutationMapping
    public RaADto createAudit(@Argument("input") RaACreateRequest input) {
        log.info("GraphQL mutation createAudit");
        try {
            return raAMapper.toDto(raAService.create(raAMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public RaADto updateAudit(@Argument("id") int id, @Argument("input") RaAUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateAudit id=" + id);
        try {
            return raAMapper.toDto(raAService.update(raAMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public boolean deleteAudit(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteAudit id=" + id);
        try {
            boolean deleted = raAService.delete(id);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Ревизия не найдена");
            }
            return true;
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public AuditExecutionResult executeAudit(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation executeAudit id=" + id);

        // Проверяем, что ревизия существует.
        raAService.getById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Ревизия не найдена"));

        // Защита от повторного запуска: статус хранится в памяти приложения.
        if (!auditExecutionRegistry.tryMarkRunning(id)) {
            return new AuditExecutionResult(false, true, "Ревизия уже выполняется");
        }

        // Вызов оркестратора (выполнение асинхронное за счёт @Async в сервисе).
        auditExecutionService.executeAudit(id);

        return new AuditExecutionResult(true, false, "Ревизия запущена");
    }

    @SchemaMapping(typeName = "Audit", field = "directory")
    public RaDirDto directory(RaADto audit) {
        if (audit == null || audit.adtDir() == null) {
            return null;
        }
        return raDirService.getById(audit.adtDir())
                .map(raDirMapper::toDto)
                .orElse(null);
    }

    @SchemaMapping(typeName = "Audit", field = "auditType")
    public RaAtDto auditType(RaADto audit) {
        if (audit == null || audit.adtType() == null) {
            return null;
        }
        return raAtService.getById(audit.adtType())
                .map(raAtMapper::toDto)
                .orElse(null);
    }
}

