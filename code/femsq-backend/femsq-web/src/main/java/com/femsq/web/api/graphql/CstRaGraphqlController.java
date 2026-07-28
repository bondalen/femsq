package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.service.CstAgPnService;
import com.femsq.database.service.CstRaListService;
import com.femsq.database.service.RaPeriodService;
import com.femsq.database.service.RaReportService;
import com.femsq.database.service.RaSummService;
import com.femsq.web.api.dto.CstAgPnSiteLookupDto;
import com.femsq.web.api.dto.CstRaListEntryDto;
import com.femsq.web.api.dto.RaPeriodLookupDto;
import com.femsq.web.api.dto.RaReportCreateRequest;
import com.femsq.web.api.dto.RaReportDto;
import com.femsq.web.api.dto.RaReportUpdateRequest;
import com.femsq.web.api.dto.RaSummCreateRequest;
import com.femsq.web.api.dto.RaSummDto;
import com.femsq.web.api.dto.RaSummUpdateRequest;
import com.femsq.web.api.mapper.CstRaMapper;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL-контроллер вкладки «отчёты» формы стройки ({@code fnRRcList} / {@code ra} / {@code ra_summ}).
 */
@Controller
public class CstRaGraphqlController {

    private static final Logger log = Logger.getLogger(CstRaGraphqlController.class.getName());

    private final CstRaListService cstRaListService;
    private final RaReportService raReportService;
    private final RaSummService raSummService;
    private final RaPeriodService raPeriodService;
    private final CstAgPnService cstAgPnService;
    private final CstRaMapper cstRaMapper;

    public CstRaGraphqlController(
            CstRaListService cstRaListService,
            RaReportService raReportService,
            RaSummService raSummService,
            RaPeriodService raPeriodService,
            CstAgPnService cstAgPnService,
            CstRaMapper cstRaMapper
    ) {
        this.cstRaListService = cstRaListService;
        this.raReportService = raReportService;
        this.raSummService = raSummService;
        this.raPeriodService = raPeriodService;
        this.cstAgPnService = cstAgPnService;
        this.cstRaMapper = cstRaMapper;
    }

    @QueryMapping
    public List<CstRaListEntryDto> cstRaList(@Argument("cstKey") int cstKey) {
        log.info(() -> "GraphQL query cstRaList cstKey=" + cstKey);
        try {
            return cstRaMapper.toListDto(cstRaListService.getForCst(cstKey));
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        }
    }

    @QueryMapping
    public RaReportDto constructionSiteReport(@Argument("id") int id) {
        log.info(() -> "GraphQL query constructionSiteReport id=" + id);
        return raReportService.getById(id).map(cstRaMapper::toDto).orElse(null);
    }

    @QueryMapping
    public List<RaSummDto> raSums(@Argument("raKey") int raKey) {
        log.info(() -> "GraphQL query raSums raKey=" + raKey);
        try {
            return cstRaMapper.toSummDto(raSummService.getForRa(raKey));
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        }
    }

    @QueryMapping
    public List<RaPeriodLookupDto> raPeriodLookups() {
        log.info("GraphQL query raPeriodLookups");
        return cstRaMapper.toPeriodDto(raPeriodService.getLookups());
    }

    @QueryMapping
    public List<CstAgPnSiteLookupDto> cstAgPnLookupsForSite(@Argument("cstKey") int cstKey) {
        log.info(() -> "GraphQL query cstAgPnLookupsForSite cstKey=" + cstKey);
        return cstRaMapper.toSiteLookupDto(cstAgPnService.getSiteLookups(cstKey));
    }

    @MutationMapping
    public RaReportDto createRaReport(@Argument("input") RaReportCreateRequest input) {
        log.info("GraphQL mutation createRaReport");
        return mutate(() -> cstRaMapper.toDto(raReportService.create(cstRaMapper.toDomain(input))));
    }

    @MutationMapping
    public RaReportDto updateRaReport(@Argument("id") int id, @Argument("input") RaReportUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateRaReport id=" + id);
        return mutate(() -> cstRaMapper.toDto(raReportService.update(cstRaMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteRaReport(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteRaReport id=" + id);
        return mutate(() -> raReportService.delete(id));
    }

    @MutationMapping
    public RaSummDto createRaSumm(@Argument("input") RaSummCreateRequest input) {
        log.info("GraphQL mutation createRaSumm");
        return mutate(() -> cstRaMapper.toDto(raSummService.create(cstRaMapper.toDomain(input))));
    }

    @MutationMapping
    public RaSummDto updateRaSumm(@Argument("id") int id, @Argument("input") RaSummUpdateRequest input) {
        log.info(() -> "GraphQL mutation updateRaSumm id=" + id);
        return mutate(() -> cstRaMapper.toDto(raSummService.update(cstRaMapper.toDomain(id, input))));
    }

    @MutationMapping
    public boolean deleteRaSumm(@Argument("id") int id) {
        log.info(() -> "GraphQL mutation deleteRaSumm id=" + id);
        return mutate(() -> raSummService.delete(id));
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
