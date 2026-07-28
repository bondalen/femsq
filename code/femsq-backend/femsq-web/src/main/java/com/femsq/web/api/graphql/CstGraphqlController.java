package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.service.CstAgPnBranchService;
import com.femsq.database.service.CstAgPnService;
import com.femsq.database.service.CstAgService;
import com.femsq.database.service.CstService;
import com.femsq.database.service.OgAgCsService;
import com.femsq.web.api.dto.CstAgCreateRequest;
import com.femsq.web.api.dto.CstAgDto;
import com.femsq.web.api.dto.CstAgPnBranchCreateRequest;
import com.femsq.web.api.dto.CstAgPnBranchDto;
import com.femsq.web.api.dto.CstAgPnBranchUpdateRequest;
import com.femsq.web.api.dto.CstAgPnCodeDto;
import com.femsq.web.api.dto.CstAgPnCreateRequest;
import com.femsq.web.api.dto.CstAgPnDto;
import com.femsq.web.api.dto.CstAgPnUpdateRequest;
import com.femsq.web.api.dto.CstAgUpdateRequest;
import com.femsq.web.api.dto.CstCreateRequest;
import com.femsq.web.api.dto.CstDto;
import com.femsq.web.api.dto.CstUpdateRequest;
import com.femsq.web.api.dto.OgAgCsLookupDto;
import com.femsq.web.api.mapper.CstAgMapper;
import com.femsq.web.api.mapper.CstAgPnBranchMapper;
import com.femsq.web.api.mapper.CstAgPnMapper;
import com.femsq.web.api.mapper.CstMapper;
import com.femsq.web.api.mapper.OgAgCsMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер иерархии строек: {@code cst} → {@code cstAg} → {@code cstAgPn} → {@code cstAgPnBranch}.
 */
@Controller
public class CstGraphqlController {

    private static final Logger log = Logger.getLogger(CstGraphqlController.class.getName());

    private final CstService cstService;
    private final CstAgService cstAgService;
    private final CstAgPnService cstAgPnService;
    private final CstAgPnBranchService cstAgPnBranchService;
    private final OgAgCsService ogAgCsService;
    private final CstMapper cstMapper;
    private final CstAgMapper cstAgMapper;
    private final CstAgPnMapper cstAgPnMapper;
    private final CstAgPnBranchMapper cstAgPnBranchMapper;
    private final OgAgCsMapper ogAgCsMapper;

    public CstGraphqlController(
            CstService cstService,
            CstAgService cstAgService,
            CstAgPnService cstAgPnService,
            CstAgPnBranchService cstAgPnBranchService,
            OgAgCsService ogAgCsService,
            CstMapper cstMapper,
            CstAgMapper cstAgMapper,
            CstAgPnMapper cstAgPnMapper,
            CstAgPnBranchMapper cstAgPnBranchMapper,
            OgAgCsMapper ogAgCsMapper
    ) {
        this.cstService = cstService;
        this.cstAgService = cstAgService;
        this.cstAgPnService = cstAgPnService;
        this.cstAgPnBranchService = cstAgPnBranchService;
        this.ogAgCsService = ogAgCsService;
        this.cstMapper = cstMapper;
        this.cstAgMapper = cstAgMapper;
        this.cstAgPnMapper = cstAgPnMapper;
        this.cstAgPnBranchMapper = cstAgPnBranchMapper;
        this.ogAgCsMapper = ogAgCsMapper;
    }

    @QueryMapping
    public List<CstDto> constructionSites() {
        log.info("GraphQL query constructionSites");
        try {
            return cstMapper.toDto(cstService.getAll());
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public CstDto constructionSite(@Argument("id") int id) {
        log.info(() -> "GraphQL query constructionSite id=" + id);
        return cstService.getById(id).map(cstMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<CstAgDto> cstAgents(@Argument("cstKey") int cstKey) {
        log.info(() -> "GraphQL query cstAgents cstKey=" + cstKey);
        try {
            return cstAgMapper.toDto(cstAgService.getForCst(cstKey));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        }
    }

    @QueryMapping
    public CstAgDto cstAgent(@Argument("id") int id) {
        log.info(() -> "GraphQL query cstAgent id=" + id);
        return cstAgService.getById(id).map(cstAgMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<CstAgPnDto> cstAgPoints(@Argument("cstaKey") int cstaKey) {
        log.info(() -> "GraphQL query cstAgPoints cstaKey=" + cstaKey);
        try {
            return cstAgPnMapper.toDto(cstAgPnService.getForCstAg(cstaKey));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        }
    }

    @QueryMapping
    public CstAgPnDto cstAgPoint(@Argument("id") int id) {
        log.info(() -> "GraphQL query cstAgPoint id=" + id);
        return cstAgPnService.getById(id).map(cstAgPnMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<CstAgPnBranchDto> cstAgPnBranches(@Argument("cstapKey") int cstapKey) {
        log.info(() -> "GraphQL query cstAgPnBranches cstapKey=" + cstapKey);
        try {
            return cstAgPnBranchMapper.toDto(cstAgPnBranchService.getForCstAgPn(cstapKey));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        }
    }

    @QueryMapping
    public CstAgPnBranchDto cstAgPnBranch(@Argument("id") int id) {
        log.info(() -> "GraphQL query cstAgPnBranch id=" + id);
        return cstAgPnBranchService.getById(id).map(cstAgPnBranchMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<OgAgCsLookupDto> ogAgCsLookups() {
        log.info("GraphQL query ogAgCsLookups");
        return ogAgCsMapper.toDto(ogAgCsService.getAll());
    }

    @QueryMapping
    public List<CstAgPnCodeDto> cstAgPnCodes(@Argument("codeFilter") String codeFilter) {
        log.info(() -> "GraphQL query cstAgPnCodes filter=" + codeFilter);
        return cstAgPnMapper.toCodeDto(cstAgPnService.getCodes(codeFilter));
    }

    @MutationMapping
    public CstDto createConstructionSite(@Argument("input") CstCreateRequest input) {
        log.info("GraphQL mutation createConstructionSite");
        return mutate(() -> cstMapper.toDto(cstService.create(cstMapper.toDomain(input))));
    }

    @MutationMapping
    public CstDto updateConstructionSite(@Argument("id") int id, @Argument("input") CstUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateConstructionSite id=" + id);
        return mutate(() -> cstMapper.toDto(cstService.update(cstMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteConstructionSite(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteConstructionSite id=" + id);
        return mutate(() -> cstService.delete(id));
    }

    @MutationMapping
    public CstAgDto createCstAgent(@Argument("input") CstAgCreateRequest input) {
        log.info("GraphQL mutation createCstAgent");
        return mutate(() -> cstAgMapper.toDto(cstAgService.create(cstAgMapper.toDomain(input))));
    }

    @MutationMapping
    public CstAgDto updateCstAgent(@Argument("id") int id, @Argument("input") CstAgUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCstAgent id=" + id);
        return mutate(() -> cstAgMapper.toDto(cstAgService.update(cstAgMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteCstAgent(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCstAgent id=" + id);
        return mutate(() -> cstAgService.delete(id));
    }

    @MutationMapping
    public CstAgPnDto createCstAgPoint(@Argument("input") CstAgPnCreateRequest input) {
        log.info("GraphQL mutation createCstAgPoint");
        return mutate(() -> cstAgPnMapper.toDto(cstAgPnService.create(cstAgPnMapper.toDomain(input))));
    }

    @MutationMapping
    public CstAgPnDto updateCstAgPoint(@Argument("id") int id, @Argument("input") CstAgPnUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCstAgPoint id=" + id);
        return mutate(() -> cstAgPnMapper.toDto(cstAgPnService.update(cstAgPnMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteCstAgPoint(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCstAgPoint id=" + id);
        return mutate(() -> cstAgPnService.delete(id));
    }

    @MutationMapping
    public CstAgPnBranchDto createCstAgPnBranch(@Argument("input") CstAgPnBranchCreateRequest input) {
        log.info("GraphQL mutation createCstAgPnBranch");
        return mutate(() -> cstAgPnBranchMapper.toDto(cstAgPnBranchService.create(cstAgPnBranchMapper.toDomain(input))));
    }

    @MutationMapping
    public CstAgPnBranchDto updateCstAgPnBranch(@Argument("id") int id, @Argument("input") CstAgPnBranchUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCstAgPnBranch id=" + id);
        return mutate(() -> cstAgPnBranchMapper.toDto(cstAgPnBranchService.update(cstAgPnBranchMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteCstAgPnBranch(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCstAgPnBranch id=" + id);
        return mutate(() -> cstAgPnBranchService.delete(id));
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
