package com.femsq.web.api.graphql;

import com.femsq.database.exception.DaoException;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgService;
import com.femsq.web.api.dto.OgAgCreateRequest;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgAgUpdateRequest;
import com.femsq.web.api.dto.OgCreateRequest;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.dto.OgUpdateRequest;
import com.femsq.web.api.mapper.OgAgMapper;
import com.femsq.web.api.mapper.OgMapper;
import java.util.List;
import java.util.Optional;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

/**
 * GraphQL-контроллер, предоставляющий операции над организациями og и ogAg.
 */
@Controller
public class OgGraphqlController {

    private static final Logger log = Logger.getLogger(OgGraphqlController.class.getName());

    private final OgService ogService;
    private final OgAgService ogAgService;
    private final OgMapper ogMapper;
    private final OgAgMapper ogAgMapper;

    public OgGraphqlController(OgService ogService, OgAgService ogAgService, OgMapper ogMapper, OgAgMapper ogAgMapper) {
        this.ogService = ogService;
        this.ogAgService = ogAgService;
        this.ogMapper = ogMapper;
        this.ogAgMapper = ogAgMapper;
    }

    @QueryMapping
    public List<OgDto> organizations() {
        log.info("GraphQL query organizations");
        return ogMapper.toDto(ogService.getAll());
    }

    @QueryMapping
    public OgDto organization(@Argument("id") int id) {
        log.info(() -> "GraphQL query organization id=" + id);
        Optional<OgDto> organization = ogService.getById(id).map(ogMapper::toDto);
        return organization.orElse(null);
    }

    @QueryMapping
    public List<OgAgDto> agents() {
        log.info("GraphQL query agents");
        return ogAgMapper.toDto(ogAgService.getAll());
    }

    @QueryMapping
    public OgAgDto agent(@Argument("id") int id) {
        log.info(() -> "GraphQL query agent id=" + id);
        return ogAgService.getById(id).map(ogAgMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<OgAgDto> organizationAgents(@Argument("organizationId") int organizationId) {
        log.info(() -> "GraphQL query organizationAgents organizationId=" + organizationId);
        return ogAgMapper.toDto(ogAgService.getForOrganization(organizationId));
    }

    @MutationMapping
    public OgDto createOrganization(@Argument("input") OgCreateRequest input) {
        log.info("GraphQL mutation createOrganization");
        try {
            return ogMapper.toDto(ogService.create(ogMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public OgDto updateOrganization(@Argument("id") int id, @Argument("input") OgUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateOrganization id=" + id);
        try {
            return ogMapper.toDto(ogService.update(ogMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public boolean deleteOrganization(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteOrganization id=" + id);
        try {
            return ogService.delete(id);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public OgAgDto createAgent(@Argument("input") OgAgCreateRequest input) {
        log.info("GraphQL mutation createAgent");
        try {
            return ogAgMapper.toDto(ogAgService.create(ogAgMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public OgAgDto updateAgent(@Argument("id") int id, @Argument("input") OgAgUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateAgent id=" + id);
        try {
            return ogAgMapper.toDto(ogAgService.update(ogAgMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }

    @MutationMapping
    public boolean deleteAgent(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteAgent id=" + id);
        try {
            return ogAgService.delete(id);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        }
    }
}
