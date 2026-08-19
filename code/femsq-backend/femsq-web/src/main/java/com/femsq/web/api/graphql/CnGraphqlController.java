package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CnContractCreate;
import com.femsq.database.model.CnInv;
import com.femsq.database.model.CnS;
import com.femsq.database.model.CnSOrg;
import com.femsq.database.model.CnSOrgSmpl;
import com.femsq.database.service.CnContractService;
import com.femsq.database.service.CnInvService;
import com.femsq.database.service.CnNumService;
import com.femsq.database.service.CnSOrgService;
import com.femsq.database.service.CnSOrgSmplService;
import com.femsq.database.service.CnSService;
import com.femsq.database.service.CnService;
import com.femsq.web.api.dto.CnContractCreateRequest;
import com.femsq.web.api.dto.CnContractCreatedDto;
import com.femsq.web.api.dto.CnDto;
import com.femsq.web.api.dto.CnInvCreateRequest;
import com.femsq.web.api.dto.CnInvDto;
import com.femsq.web.api.dto.CnInvUpdateRequest;
import com.femsq.web.api.dto.CnNumDto;
import com.femsq.web.api.dto.CnNumTypeLookupDto;
import com.femsq.web.api.dto.CnUpdateRequest;
import com.femsq.web.api.dto.CnSOrgCreateRequest;
import com.femsq.web.api.dto.CnSOrgDto;
import com.femsq.web.api.dto.CnSOrgIdLookupDto;
import com.femsq.web.api.dto.CnSOrgSmplCreateRequest;
import com.femsq.web.api.dto.CnSOrgSmplDto;
import com.femsq.web.api.dto.CnSOrgSmplUpdateRequest;
import com.femsq.web.api.dto.CnSOrgUpdateRequest;
import com.femsq.web.api.dto.CnSideCreateRequest;
import com.femsq.web.api.dto.CnSideDto;
import com.femsq.web.api.dto.CnSideUpdateRequest;
import com.femsq.web.api.mapper.CnMapper;
import com.femsq.web.api.mapper.CnPartyMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL API экрана «Договоры»: cnNum/cn и CRUD сторон.
 */
@Controller
public class CnGraphqlController {

    private static final Logger log = Logger.getLogger(CnGraphqlController.class.getName());

    private final CnNumService cnNumService;
    private final CnService cnService;
    private final CnContractService cnContractService;
    private final CnInvService cnInvService;
    private final CnSService cnSService;
    private final CnSOrgSmplService cnSOrgSmplService;
    private final CnSOrgService cnSOrgService;
    private final CnMapper cnMapper;
    private final CnPartyMapper cnPartyMapper;

    public CnGraphqlController(
            CnNumService cnNumService,
            CnService cnService,
            CnContractService cnContractService,
            CnInvService cnInvService,
            CnSService cnSService,
            CnSOrgSmplService cnSOrgSmplService,
            CnSOrgService cnSOrgService,
            CnMapper cnMapper,
            CnPartyMapper cnPartyMapper
    ) {
        this.cnNumService = cnNumService;
        this.cnService = cnService;
        this.cnContractService = cnContractService;
        this.cnInvService = cnInvService;
        this.cnSService = cnSService;
        this.cnSOrgSmplService = cnSOrgSmplService;
        this.cnSOrgService = cnSOrgService;
        this.cnMapper = cnMapper;
        this.cnPartyMapper = cnPartyMapper;
    }

    @QueryMapping
    public List<CnNumDto> cnNums() {
        log.info("GraphQL query cnNums");
        try {
            return cnMapper.toCnNumDto(cnNumService.getAll());
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public List<CnNumDto> cnNumsByCn(@Argument("cnKey") int cnKey) {
        log.info(() -> "GraphQL query cnNumsByCn cnKey=" + cnKey);
        try {
            return cnMapper.toCnNumDto(cnNumService.getByCnKey(cnKey));
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public CnDto cn(@Argument("cnKey") int cnKey) {
        log.info(() -> "GraphQL query cn cnKey=" + cnKey);
        try {
            return cnService.getById(cnKey).map(cnMapper::toDto).orElse(null);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public List<CnSideDto> cnSides(@Argument("cnKey") int cnKey) {
        log.info(() -> "GraphQL query cnSides cnKey=" + cnKey);
        return mutate(() -> cnPartyMapper.toTree(
                cnSService.getForCn(cnKey),
                cnSOrgSmplService.getForCn(cnKey),
                cnSOrgService.getForCn(cnKey)
        ));
    }

    @QueryMapping
    public List<CnSOrgIdLookupDto> cnSOrgIdLookups() {
        log.info("GraphQL query cnSOrgIdLookups");
        return mutate(() -> cnPartyMapper.toLookupDto(cnSOrgSmplService.getOrgIdLookups()));
    }

    @QueryMapping
    public List<CnNumTypeLookupDto> cnNumTypes() {
        log.info("GraphQL query cnNumTypes");
        return mutate(() -> cnContractService.getNumTypes().stream()
                .map(row -> new CnNumTypeLookupDto(row.cnntKey(), row.cnntName()))
                .toList());
    }

    @QueryMapping
    public int cnNumDuplicateCount(@Argument("cnnNum") String cnnNum) {
        log.info(() -> "GraphQL query cnNumDuplicateCount cnnNum=" + cnnNum);
        return mutate(() -> cnContractService.countByCnnNum(cnnNum));
    }

    @MutationMapping
    public CnContractCreatedDto createCnContract(@Argument("input") CnContractCreateRequest input) {
        log.info("GraphQL mutation createCnContract");
        return mutate(() -> {
            var created = cnContractService.createWithPerformer(new CnContractCreate(
                    input.cnnNum(),
                    input.csoCnDate(),
                    input.cnnType(),
                    input.csosOrgId(),
                    input.note()
            ));
            return new CnContractCreatedDto(
                    created.cnKey(),
                    created.cnnKey(),
                    created.cnSKey(),
                    created.csosKey(),
                    created.cnSOrgKey()
            );
        });
    }

    @MutationMapping
    public CnDto updateCn(@Argument("id") int id, @Argument("input") CnUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCn id=" + id);
        return mutate(() -> cnMapper.toDto(cnService.update(cnMapper.toDomain(id, input))));
    }

    @MutationMapping
    public CnInvDto createCnInv(@Argument("input") CnInvCreateRequest input) {
        log.info("GraphQL mutation createCnInv");
        return mutate(() -> toCnInvDto(cnInvService.create(input.ciInv(), input.ciCn())));
    }

    @MutationMapping
    public CnInvDto updateCnInv(@Argument("id") int id, @Argument("input") CnInvUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCnInv id=" + id);
        return mutate(() -> toCnInvDto(cnInvService.update(id, input.ciInv(), input.ciCn())));
    }

    @MutationMapping
    public boolean deleteCnInv(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCnInv id=" + id);
        return mutate(() -> cnInvService.delete(id));
    }

    @MutationMapping
    public CnSideDto createCnSide(@Argument("input") CnSideCreateRequest input) {
        log.info("GraphQL mutation createCnSide");
        return mutate(() -> {
            CnS created = cnSService.create(cnPartyMapper.toDomain(input));
            return cnPartyMapper.toSideDto(created, List.of());
        });
    }

    @MutationMapping
    public CnSideDto updateCnSide(@Argument("id") int id, @Argument("input") CnSideUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCnSide id=" + id);
        return mutate(() -> {
            CnS updated = cnSService.update(cnPartyMapper.toDomain(id, input));
            return cnPartyMapper.toSideDto(updated, List.of());
        });
    }

    @MutationMapping
    public boolean deleteCnSide(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCnSide id=" + id);
        return mutate(() -> cnSService.delete(id));
    }

    @MutationMapping
    public CnSOrgSmplDto createCnSOrgSmpl(@Argument("input") CnSOrgSmplCreateRequest input) {
        log.info("GraphQL mutation createCnSOrgSmpl");
        return mutate(() -> {
            CnSOrgSmpl created = cnSOrgSmplService.create(cnPartyMapper.toDomain(input));
            return cnPartyMapper.toSmplDto(created, List.of());
        });
    }

    @MutationMapping
    public CnSOrgSmplDto updateCnSOrgSmpl(@Argument("id") int id, @Argument("input") CnSOrgSmplUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCnSOrgSmpl id=" + id);
        return mutate(() -> {
            CnSOrgSmpl updated = cnSOrgSmplService.update(cnPartyMapper.toDomain(id, input));
            return cnPartyMapper.toSmplDto(updated, List.of());
        });
    }

    @MutationMapping
    public boolean deleteCnSOrgSmpl(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCnSOrgSmpl id=" + id);
        return mutate(() -> cnSOrgSmplService.delete(id));
    }

    @MutationMapping
    public CnSOrgDto createCnSOrg(@Argument("input") CnSOrgCreateRequest input) {
        log.info("GraphQL mutation createCnSOrg");
        return mutate(() -> {
            CnSOrg created = cnSOrgService.create(cnPartyMapper.toDomain(input));
            return cnPartyMapper.toOrgDto(created);
        });
    }

    @MutationMapping
    public CnSOrgDto updateCnSOrg(@Argument("id") int id, @Argument("input") CnSOrgUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateCnSOrg id=" + id);
        return mutate(() -> {
            CnSOrg updated = cnSOrgService.update(cnPartyMapper.toDomain(id, input));
            return cnPartyMapper.toOrgDto(updated);
        });
    }

    @MutationMapping
    public boolean deleteCnSOrg(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteCnSOrg id=" + id);
        return mutate(() -> cnSOrgService.delete(id));
    }

    private <T> T mutate(Mutator<T> mutator) {
        try {
            return mutator.run();
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
        } catch (DaoException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    private static ResponseStatusException unavailable(MissingConfigurationException exception) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
    }

    private static CnInvDto toCnInvDto(CnInv row) {
        return new CnInvDto(row.ciKey(), row.ciInv(), row.ciCn(), row.ciTimeOfEntry());
    }

    @FunctionalInterface
    private interface Mutator<T> {
        T run();
    }
}
