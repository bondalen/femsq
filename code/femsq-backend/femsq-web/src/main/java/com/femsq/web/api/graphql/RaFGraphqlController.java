package com.femsq.web.api.graphql;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RaFService;
import com.femsq.database.service.RaFtService;
import com.femsq.web.api.dto.RaFCreateRequest;
import com.femsq.web.api.dto.RaFDto;
import com.femsq.web.api.dto.RaFUpdateRequest;
import com.femsq.web.api.dto.RaFtDto;
import com.femsq.web.api.mapper.RaFMapper;
import com.femsq.web.api.mapper.RaFtMapper;
import java.util.List;
import java.util.Optional;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер домена файлов ревизий (ags.ra_f) и справочника типов файлов (ags.ra_ft).
 *
 * <p>Реализует:</p>
 * <ul>
 *   <li>Query: {@code files}, {@code file}, {@code filesByDirectory}, {@code fileTypes}</li>
 *   <li>Mutation: {@code createFile}, {@code updateFile}, {@code deleteFile}</li>
 * </ul>
 */
@Controller
public class RaFGraphqlController {

    private static final Logger log = Logger.getLogger(RaFGraphqlController.class.getName());

    private final RaFService raFService;
    private final RaFtService raFtService;
    private final RaFMapper raFMapper;
    private final RaFtMapper raFtMapper;

    public RaFGraphqlController(
            RaFService raFService,
            RaFtService raFtService,
            RaFMapper raFMapper,
            RaFtMapper raFtMapper) {
        this.raFService = raFService;
        this.raFtService = raFtService;
        this.raFMapper = raFMapper;
        this.raFtMapper = raFtMapper;
    }

    @QueryMapping
    public List<RaFDto> files() {
        log.info("GraphQL query files");
        return raFMapper.toDto(raFService.getAll());
    }

    @QueryMapping
    public RaFDto file(@Argument("id") int id) {
        log.info(() -> "GraphQL query file id=" + id);
        Optional<RaFDto> file = raFService.getById(id).map(raFMapper::toDto);
        return file.orElse(null);
    }

    @QueryMapping
    public List<RaFDto> filesByDirectory(@Argument("dirId") int dirId) {
        log.info(() -> "GraphQL query filesByDirectory dirId=" + dirId);
        return raFMapper.toDto(raFService.getByDirId(dirId));
    }

    @QueryMapping
    public List<RaFtDto> fileTypes() {
        log.info("GraphQL query fileTypes");
        return raFtMapper.toDto(raFtService.getAll());
    }

    @MutationMapping
    public RaFDto createFile(@Argument("input") RaFCreateRequest input) {
        log.info("GraphQL mutation createFile");
        try {
            return raFMapper.toDto(raFService.create(raFMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public RaFDto updateFile(@Argument("id") int id, @Argument("input") RaFUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateFile id=" + id);
        try {
            return raFMapper.toDto(raFService.update(raFMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public boolean deleteFile(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteFile id=" + id);
        try {
            boolean deleted = raFService.delete(id);
            if (!deleted) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Файл не найден");
            }
            return true;
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}

