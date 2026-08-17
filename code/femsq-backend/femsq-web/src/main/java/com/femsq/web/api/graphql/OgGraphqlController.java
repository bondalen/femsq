package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.Og;
import com.femsq.database.model.OgNmF;
import com.femsq.database.model.OrgId;
import com.femsq.database.service.OgAgService;
import com.femsq.database.service.OgNmFService;
import com.femsq.database.service.OgService;
import com.femsq.database.service.OrgIdService;
import com.femsq.web.api.dto.AttachOrganizationIdsInput;
import com.femsq.web.api.dto.CreateOgNmFInput;
import com.femsq.web.api.dto.CreateOrganizationWithIdsInput;
import com.femsq.web.api.dto.OgAgCreateRequest;
import com.femsq.web.api.dto.OgAgDto;
import com.femsq.web.api.dto.OgAgUpdateRequest;
import com.femsq.web.api.dto.OgCreateRequest;
import com.femsq.web.api.dto.OgDto;
import com.femsq.web.api.dto.OgNmFDto;
import com.femsq.web.api.dto.OgUpdateRequest;
import com.femsq.web.api.dto.OrgIdDto;
import com.femsq.web.api.dto.UpdateOgNmFInput;
import com.femsq.web.api.dto.UpdateOrganizationIdInput;
import com.femsq.web.api.mapper.OgAgMapper;
import com.femsq.web.api.mapper.OgMapper;
import com.femsq.web.api.mapper.OgNmFMapper;
import com.femsq.web.api.mapper.OrgIdMapper;
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
 * GraphQL-контроллер организаций: {@code og}, {@code org_id}, {@code ogNmF}, {@code ogAg}.
 */
@Controller
public class OgGraphqlController {

    private static final Logger log = Logger.getLogger(OgGraphqlController.class.getName());

    private final OgService ogService;
    private final OgAgService ogAgService;
    private final OrgIdService orgIdService;
    private final OgNmFService ogNmFService;
    private final OgMapper ogMapper;
    private final OgAgMapper ogAgMapper;
    private final OrgIdMapper orgIdMapper;
    private final OgNmFMapper ogNmFMapper;

    /**
     * @param ogService организации
     * @param ogAgService агенты
     * @param orgIdService идентификаторы
     * @param ogNmFService варианты имён
     * @param ogMapper маппер og
     * @param ogAgMapper маппер агентов
     * @param orgIdMapper маппер org_id
     * @param ogNmFMapper маппер ogNmF
     */
    public OgGraphqlController(
            OgService ogService,
            OgAgService ogAgService,
            OrgIdService orgIdService,
            OgNmFService ogNmFService,
            OgMapper ogMapper,
            OgAgMapper ogAgMapper,
            OrgIdMapper orgIdMapper,
            OgNmFMapper ogNmFMapper
    ) {
        this.ogService = ogService;
        this.ogAgService = ogAgService;
        this.orgIdService = orgIdService;
        this.ogNmFService = ogNmFService;
        this.ogMapper = ogMapper;
        this.ogAgMapper = ogAgMapper;
        this.orgIdMapper = orgIdMapper;
        this.ogNmFMapper = ogNmFMapper;
    }

    @QueryMapping
    public List<OgDto> organizations() {
        log.info("GraphQL query organizations");
        try {
            return ogMapper.toDto(ogService.getAll());
        } catch (MissingConfigurationException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
        }
    }

    @QueryMapping
    public OgDto organization(@Argument("id") int id) {
        Optional<OgDto> organization = ogService.getById(id).map(ogMapper::toDto);
        return organization.orElse(null);
    }

    @QueryMapping
    public List<OgAgDto> agents() {
        return ogAgMapper.toDto(ogAgService.getAll());
    }

    @QueryMapping
    public OgAgDto agent(@Argument("id") int id) {
        return ogAgService.getById(id).map(ogAgMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<OgAgDto> organizationAgents(@Argument("organizationId") int organizationId) {
        return ogAgMapper.toDto(ogAgService.getForOrganization(organizationId));
    }

    @QueryMapping
    public List<OrgIdDto> organizationIds(@Argument("organizationId") int organizationId) {
        try {
            return orgIdMapper.toDto(orgIdService.listByOrg(organizationId));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @QueryMapping
    public List<OgNmFDto> organizationNameVariants(@Argument("organizationId") int organizationId) {
        try {
            return ogNmFMapper.toDto(ogNmFService.listByOrg(organizationId));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgDto createOrganization(@Argument("input") OgCreateRequest input) {
        try {
            return ogMapper.toDto(ogService.create(ogMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgDto createOrganizationWithIds(@Argument("input") CreateOrganizationWithIdsInput input) {
        try {
            Og domain = new Og(
                    null,
                    input.ogName(),
                    input.ogOfficialName(),
                    input.ogFullName(),
                    input.ogDescription(),
                    null,
                    null,
                    null,
                    null,
                    null,
                    input.registrationTaxType() == null
                            ? null
                            : input.registrationTaxType().trim().toLowerCase()
            );
            return ogMapper.toDto(orgIdService.createOrganizationWithIds(
                    domain, input.buirg(), input.itn(), input.itnExt()));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public List<OrgIdDto> attachOrganizationIds(@Argument("input") AttachOrganizationIdsInput input) {
        try {
            return orgIdMapper.toDto(orgIdService.attachIds(
                    input.ogKey(), input.buirg(), input.itn(), input.itnExt()));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OrgIdDto updateOrganizationId(@Argument("input") UpdateOrganizationIdInput input) {
        try {
            OrgId updated = orgIdService.update(new OrgId(
                    input.orgIdKey(),
                    input.org(),
                    input.orgIdType(),
                    input.orgIdValueL(),
                    input.orgIdValueT(),
                    input.orgIdValueTExt()
            ));
            return orgIdMapper.toDto(updated);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgNmFDto createOrganizationNameVariant(@Argument("input") CreateOgNmFInput input) {
        try {
            return ogNmFMapper.toDto(ogNmFService.create(new OgNmF(
                    null,
                    input.onfOg(),
                    input.onfName(),
                    input.onfNameExt(),
                    input.onfStart(),
                    input.onfEnd()
            )));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgNmFDto updateOrganizationNameVariant(@Argument("input") UpdateOgNmFInput input) {
        try {
            return ogNmFMapper.toDto(ogNmFService.update(new OgNmF(
                    input.onfKey(),
                    input.onfOg(),
                    input.onfName(),
                    input.onfNameExt(),
                    input.onfStart(),
                    input.onfEnd()
            )));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public boolean deleteOrganizationNameVariant(@Argument("onfKey") int onfKey) {
        try {
            return ogNmFService.delete(onfKey);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgDto updateOrganization(@Argument("id") int id, @Argument("input") OgUpdateRequest input) {
        try {
            return ogMapper.toDto(ogService.update(ogMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public boolean deleteOrganization(@Argument("id") int id) {
        try {
            return ogService.delete(id);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgAgDto createAgent(@Argument("input") OgAgCreateRequest input) {
        try {
            return ogAgMapper.toDto(ogAgService.create(ogAgMapper.toDomain(input)));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public OgAgDto updateAgent(@Argument("id") int id, @Argument("input") OgAgUpdateRequest input) {
        try {
            return ogAgMapper.toDto(ogAgService.update(ogAgMapper.toDomain(id, input)));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    @MutationMapping
    public boolean deleteAgent(@Argument("id") int id) {
        try {
            return ogAgService.delete(id);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    private static ResponseStatusException badRequest(IllegalArgumentException exception) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
    }

    private static ResponseStatusException unavailable(MissingConfigurationException exception) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
    }

    private static ResponseStatusException internal(DaoException exception) {
        return new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
    }
}
