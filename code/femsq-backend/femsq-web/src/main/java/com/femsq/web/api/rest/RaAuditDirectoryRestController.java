package com.femsq.web.api.rest;

import com.femsq.database.service.RaAService;
import com.femsq.database.service.RaDirService;
import com.femsq.web.api.dto.RaDirDto;
import com.femsq.web.api.mapper.RaDirMapper;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * REST-контроллер для получения директории ревизии.
 * Реализует связь 1:1 между ревизией и директорией.
 */
@RestController
@RequestMapping("/api/ra/audits")
public class RaAuditDirectoryRestController {

    private static final Logger log = Logger.getLogger(RaAuditDirectoryRestController.class.getName());

    private final RaAService raAService;
    private final RaDirService raDirService;
    private final RaDirMapper raDirMapper;

    public RaAuditDirectoryRestController(
            RaAService raAService,
            RaDirService raDirService,
            RaDirMapper raDirMapper) {
        this.raAService = raAService;
        this.raDirService = raDirService;
        this.raDirMapper = raDirMapper;
    }

    /**
     * Возвращает директорию для указанной ревизии.
     * В форме ревизии всегда одна директория (связь 1:1).
     */
    @GetMapping("/{auditId}/directory")
    public RaDirDto getDirectoryByAuditId(@PathVariable("auditId") long auditId) {
        log.info(() -> "Handling GET /api/ra/audits/" + auditId + "/directory");
        
        // Получаем ревизию
        var audit = raAService.getById(auditId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Ревизия с идентификатором " + auditId + " не найдена"));
        
        // Получаем директорию ревизии через поле adtDir
        int dirId = audit.adtDir();
        return raDirService.getById(dirId)
                .map(raDirMapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Директория с идентификатором " + dirId + " не найдена"));
    }
}
