package com.femsq.web.api.graphql;

import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlP;
import com.femsq.database.model.IpgUtPlPnLmMnCell;
import com.femsq.database.model.IpgUtPlPnLmMnGrid;
import com.femsq.database.model.IpgUtPlPnLmMnMonth;
import com.femsq.database.service.IpgUtPlService;
import com.femsq.web.api.dto.IpgUtPlDto;
import com.femsq.web.api.dto.IpgUtPlPDto;
import com.femsq.web.api.dto.IpgUtPlPnLmMnCellDto;
import com.femsq.web.api.dto.IpgUtPlPnLmMnGridDto;
import com.femsq.web.api.dto.IpgUtPlPnLmMnMonthDto;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/**
 * GraphQL UtPl / LmMn (C2 O2 §4.2): планы текущей ИП, грид месяц×stCost, upsert + AggAxis.
 */
@Controller
public class IpgUtPlGraphqlController {

    private static final Logger log = Logger.getLogger(IpgUtPlGraphqlController.class.getName());

    private final IpgUtPlService utPlService;

    public IpgUtPlGraphqlController(IpgUtPlService utPlService) {
        this.utPlService = utPlService;
    }

    @QueryMapping
    public List<IpgUtPlDto> ipgUtPlByIpg(@Argument("ipgKey") int ipgKey) {
        return utPlService.listUtPlByIpg(ipgKey).stream()
                .map(this::toUtPlDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public List<IpgUtPlPDto> ipgUtPlPByPlan(@Argument("plKey") int plKey) {
        return utPlService.listUtPlPByPlan(plKey).stream()
                .map(this::toUtPlPDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public IpgUtPlPnLmMnGridDto ipgUtPlPnLmMnGrid(
            @Argument("plKey") int plKey,
            @Argument("ipgpKey") int ipgpKey) {
        return toGridDto(utPlService.loadLmMnGrid(plKey, ipgpKey));
    }

    @MutationMapping
    public IpgUtPlDto createIpgUtPl(@Argument("input") CreateIpgUtPlInput input) {
        log.info(() -> "createIpgUtPl ipg=" + input.ipgKey() + " ag=" + input.agKey());
        return toUtPlDto(utPlService.createUtPl(
                input.ipgKey(),
                input.agKey(),
                input.name(),
                input.date()));
    }

    @MutationMapping
    public IpgUtPlPDto ensureIpgUtPlP(
            @Argument("plKey") int plKey,
            @Argument("ipgpKey") int ipgpKey) {
        return toUtPlPDto(utPlService.ensureUtPlP(plKey, ipgpKey));
    }

    @MutationMapping
    public IpgUtPlPnLmMnGridDto upsertIpgUtPlPnLmMnMonth(
            @Argument("input") UpsertIpgUtPlPnLmMnMonthInput input) {
        log.info(() -> "upsertIpgUtPlPnLmMnMonth pl=" + input.plKey()
                + " pn=" + input.ipgpKey() + " m=" + input.month());
        return toGridDto(utPlService.upsertLmMnMonth(
                input.plKey(),
                input.ipgpKey(),
                input.month(),
                toBd(input.lim212()),
                toBd(input.lim195()),
                toBd(input.lim172()),
                toBd(input.lim187())));
    }

    private IpgUtPlDto toUtPlDto(IpgUtPl model) {
        return new IpgUtPlDto(
                model.iuplKey(),
                model.iuplNm(),
                model.iuplDate(),
                model.iuplAg(),
                model.iuplIpg());
    }

    private IpgUtPlPDto toUtPlPDto(IpgUtPlP model) {
        return new IpgUtPlPDto(
                model.iuplpKey(),
                model.iuplpPl(),
                model.iuplpIpgPn(),
                model.iuplpLim(),
                model.iuplpSubAg());
    }

    private IpgUtPlPnLmMnGridDto toGridDto(IpgUtPlPnLmMnGrid grid) {
        return new IpgUtPlPnLmMnGridDto(
                grid.plPnKey(),
                grid.limYear(),
                grid.months().stream().map(this::toMonthDto).collect(Collectors.toList()),
                grid.cells().stream().map(this::toCellDto).collect(Collectors.toList()),
                grid.gAggOk());
    }

    private IpgUtPlPnLmMnMonthDto toMonthDto(IpgUtPlPnLmMnMonth month) {
        return new IpgUtPlPnLmMnMonthDto(
                month.plPnKey(),
                month.month(),
                month.lim212(),
                month.lim195(),
                month.lim172(),
                month.lim187(),
                month.aggCode());
    }

    private IpgUtPlPnLmMnCellDto toCellDto(IpgUtPlPnLmMnCell cell) {
        return new IpgUtPlPnLmMnCellDto(
                cell.iuplpmKey(),
                cell.iuplpmPlPn(),
                cell.iuplpmStCost(),
                cell.iuplpmMn(),
                cell.iuplpmLim());
    }

    private static BigDecimal toBd(Double value) {
        return value == null ? null : BigDecimal.valueOf(value);
    }

    /**
     * Input создания {@code ipgUtPl}.
     */
    public record CreateIpgUtPlInput(
            int ipgKey,
            int agKey,
            String name,
            LocalDate date
    ) {
    }

    /**
     * Input upsert оси C месяца.
     */
    public record UpsertIpgUtPlPnLmMnMonthInput(
            int plKey,
            int ipgpKey,
            int month,
            Double lim212,
            Double lim195,
            Double lim172,
            Double lim187
    ) {
    }
}
