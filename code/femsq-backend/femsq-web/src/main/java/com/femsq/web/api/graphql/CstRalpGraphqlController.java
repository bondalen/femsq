package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.service.RalpRaAuService;
import com.femsq.database.service.RalpRaAuStatusService;
import com.femsq.database.service.RalpRaCstListService;
import com.femsq.database.service.RalpRaService;
import com.femsq.web.api.dto.RalpRaAuCreateRequest;
import com.femsq.web.api.dto.RalpRaAuDto;
import com.femsq.web.api.dto.RalpRaAuStatusLookupDto;
import com.femsq.web.api.dto.RalpRaAuUpdateRequest;
import com.femsq.web.api.dto.RalpRaCreateRequest;
import com.femsq.web.api.dto.RalpRaCstListEntryDto;
import com.femsq.web.api.dto.RalpRaDto;
import com.femsq.web.api.dto.RalpRaUpdateRequest;
import com.femsq.web.api.mapper.CstRalpMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер вкладки «отчёты, аренда» ({@code ralpRaCst} / {@code ralpRa} / {@code ralpRaAu}).
 */
@Controller
public class CstRalpGraphqlController {

    private static final Logger log = Logger.getLogger(CstRalpGraphqlController.class.getName());

    private final RalpRaCstListService ralpRaCstListService;
    private final RalpRaService ralpRaService;
    private final RalpRaAuService ralpRaAuService;
    private final RalpRaAuStatusService ralpRaAuStatusService;
    private final CstRalpMapper cstRalpMapper;

    public CstRalpGraphqlController(
            RalpRaCstListService ralpRaCstListService,
            RalpRaService ralpRaService,
            RalpRaAuService ralpRaAuService,
            RalpRaAuStatusService ralpRaAuStatusService,
            CstRalpMapper cstRalpMapper
    ) {
        this.ralpRaCstListService = ralpRaCstListService;
        this.ralpRaService = ralpRaService;
        this.ralpRaAuService = ralpRaAuService;
        this.ralpRaAuStatusService = ralpRaAuStatusService;
        this.cstRalpMapper = cstRalpMapper;
    }

    @QueryMapping
    public List<RalpRaCstListEntryDto> cstRalpRaList(@Argument("cstKey") int cstKey) {
        log.info(() -> "GraphQL query cstRalpRaList cstKey=" + cstKey);
        try {
            return cstRalpMapper.toListDto(ralpRaCstListService.getForCst(cstKey));
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public RalpRaDto ralpRa(@Argument("id") int id) {
        log.info(() -> "GraphQL query ralpRa id=" + id);
        return ralpRaService.getById(id).map(cstRalpMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<RalpRaAuDto> ralpRaAus(@Argument("ralprKey") int ralprKey) {
        log.info(() -> "GraphQL query ralpRaAus ralprKey=" + ralprKey);
        try {
            return cstRalpMapper.toAuDto(ralpRaAuService.getForRa(ralprKey));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        }
    }

    @QueryMapping
    public List<RalpRaAuStatusLookupDto> ralpRaAuStatusLookups() {
        log.info("GraphQL query ralpRaAuStatusLookups");
        return cstRalpMapper.toStatusDto(ralpRaAuStatusService.getLookups());
    }

    @MutationMapping
    public RalpRaDto createRalpRa(@Argument("input") RalpRaCreateRequest input) {
        log.info("GraphQL mutation createRalpRa");
        return mutate(() -> cstRalpMapper.toDto(ralpRaService.create(cstRalpMapper.toDomain(input))));
    }

    @MutationMapping
    public RalpRaDto updateRalpRa(@Argument("id") int id, @Argument("input") RalpRaUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateRalpRa id=" + id);
        return mutate(() -> cstRalpMapper.toDto(ralpRaService.update(cstRalpMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteRalpRa(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteRalpRa id=" + id);
        return mutate(() -> ralpRaService.delete(id));
    }

    @MutationMapping
    public RalpRaAuDto createRalpRaAu(@Argument("input") RalpRaAuCreateRequest input) {
        log.info("GraphQL mutation createRalpRaAu");
        return mutate(() -> cstRalpMapper.toDto(ralpRaAuService.create(cstRalpMapper.toDomain(input))));
    }

    @MutationMapping
    public RalpRaAuDto updateRalpRaAu(@Argument("id") int id, @Argument("input") RalpRaAuUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateRalpRaAu id=" + id);
        return mutate(() -> cstRalpMapper.toDto(ralpRaAuService.update(cstRalpMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteRalpRaAu(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteRalpRaAu id=" + id);
        return mutate(() -> ralpRaAuService.delete(id));
    }

    private <T> T mutate(Mutator<T> mutator) {
        try {
            return mutator.run();
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    private ResponseStatusException badRequest(IllegalArgumentException exception) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
    }

    private ResponseStatusException unavailable(MissingConfigurationException exception) {
        log.warning("Database configuration is missing: " + exception.getMessage());
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
    }

    @FunctionalInterface
    private interface Mutator<T> {
        T run();
    }
}
