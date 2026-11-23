package com.femsq.web.api.graphql;

import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgSh;
import com.femsq.database.model.IpgStPn;
import com.femsq.database.service.IpgLeavesService;
import com.femsq.web.api.dto.IpgFullDto;
import com.femsq.web.api.dto.IpgPnDto;
import com.femsq.web.api.dto.IpgShDto;
import com.femsq.web.api.dto.IpgStPnDto;
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
 * GraphQL Leaves (C2 §2.4.2): полная {@code ipg}, пункты {@code ipgPn}, {@code ipgStPn}.
 */
@Controller
public class IpgLeavesGraphqlController {

    private static final Logger log = Logger.getLogger(IpgLeavesGraphqlController.class.getName());

    private final IpgLeavesService leavesService;

    public IpgLeavesGraphqlController(IpgLeavesService leavesService) {
        this.leavesService = leavesService;
    }

    @QueryMapping
    public List<IpgFullDto> investmentProgramsFull(
            @Argument("year") Integer year,
            @Argument("ogKey") Integer ogKey,
            @Argument("name") String name) {
        return leavesService.listIpgs(year, ogKey, name).stream()
                .map(this::toIpgDto)
                .collect(Collectors.toList());
    }

    @QueryMapping
    public IpgFullDto investmentProgramFull(@Argument("id") int id) {
        return leavesService.getIpg(id).map(this::toIpgDto).orElse(null);
    }

    @QueryMapping
    public List<IpgPnDto> investmentProgramPoints(@Argument("ipgKey") int ipgKey) {
        return leavesService.listPns(ipgKey).stream().map(this::toPnDto).collect(Collectors.toList());
    }

    @QueryMapping
    public IpgPnDto investmentProgramPoint(@Argument("id") int id) {
        return leavesService.getPn(id).map(this::toPnDto).orElse(null);
    }

    @QueryMapping
    public List<IpgStPnDto> ipgPnStructure(@Argument("ipgpKey") int ipgpKey) {
        return leavesService.listStPn(ipgpKey).stream().map(this::toStPnDto).collect(Collectors.toList());
    }

    @QueryMapping
    public List<IpgShDto> ipgSchemes() {
        return leavesService.listSh().stream().map(this::toShDto).collect(Collectors.toList());
    }

    @MutationMapping
    public IpgFullDto createInvestmentProgram(@Argument("input") CreateIpgInput input) {
        log.info(() -> "createInvestmentProgram og=" + input.ipgOg());
        return toIpgDto(leavesService.createIpg(
                input.ipgOg(),
                input.ipgNm(),
                input.ipgYy(),
                input.ipgNum().shortValue(),
                input.ipgStr(),
                input.ipgEnd(),
                input.ipgRepl(),
                input.ipgStRlSh(),
                input.ipgYyYear()));
    }

    @MutationMapping
    public IpgFullDto updateInvestmentProgram(
            @Argument("id") int id,
            @Argument("input") UpdateIpgInput input) {
        return toIpgDto(leavesService.updateIpg(
                id,
                input.ipgNm(),
                input.ipgYy(),
                input.ipgNum().shortValue(),
                input.ipgStr(),
                input.ipgEnd(),
                input.ipgRepl(),
                input.ipgStRlSh(),
                input.ipgYyYear()));
    }

    @MutationMapping
    public IpgPnDto createIpgPn(@Argument("input") CreateIpgPnInput input) {
        log.info(() -> "createIpgPn ipg=" + input.ipgpIpg() + " cstAgPn=" + input.ipgpCstAgPn());
        return toPnDto(leavesService.createPn(
                input.ipgpIpg(),
                input.ipgpNum(),
                input.ipgpCstAgPn(),
                input.ipgpSh(),
                input.ipgpSmTtl(),
                input.ipgpSmWrk(),
                input.ipgpSmEqu(),
                input.ipgpSmOth(),
                input.ipgpSmAgFee(),
                input.ipgpCostAdjust(),
                input.ipgpSmReserv(),
                input.ipgpTskCms()));
    }

    @MutationMapping
    public IpgPnDto updateIpgPn(@Argument("id") int id, @Argument("input") UpdateIpgPnInput input) {
        return toPnDto(leavesService.updatePn(
                id,
                input.ipgpNum(),
                input.ipgpCstAgPn(),
                input.ipgpSh(),
                input.ipgpSmTtl(),
                input.ipgpSmWrk(),
                input.ipgpSmEqu(),
                input.ipgpSmOth(),
                input.ipgpSmAgFee(),
                input.ipgpCostAdjust(),
                input.ipgpSmReserv(),
                input.ipgpTskCms()));
    }

    @MutationMapping
    public Boolean deleteIpgPn(@Argument("id") int id) {
        leavesService.deletePn(id);
        return Boolean.TRUE;
    }

    @MutationMapping
    public IpgStPnDto addIpgPnStructure(
            @Argument("ipgpKey") int ipgpKey,
            @Argument("stiKey") int stiKey) {
        return toStPnDto(leavesService.addStPn(ipgpKey, stiKey));
    }

    @MutationMapping
    public Boolean removeIpgPnStructure(@Argument("ipgspKey") int ipgspKey) {
        leavesService.removeStPn(ipgspKey);
        return Boolean.TRUE;
    }

    @MutationMapping
    public List<IpgStPnDto> setIpgPnStructure(
            @Argument("ipgpKey") int ipgpKey,
            @Argument("stiKeys") List<Integer> stiKeys) {
        return leavesService.setStPn(ipgpKey, stiKeys).stream()
                .map(this::toStPnDto)
                .collect(Collectors.toList());
    }

    private IpgFullDto toIpgDto(IpgFull ipg) {
        return new IpgFullDto(
                ipg.ipgKey(),
                ipg.ipgOg(),
                ipg.ogName(),
                ipg.ipgNm(),
                ipg.ipgYy(),
                ipg.year(),
                (int) ipg.ipgNum(),
                ipg.ipgStr(),
                ipg.ipgEnd(),
                ipg.ipgRepl(),
                ipg.ipgStRlSh(),
                ipg.stNetName(),
                ipg.ipgYyYear()
        );
    }

    private IpgPnDto toPnDto(IpgPn pn) {
        return new IpgPnDto(
                pn.ipgpKey(),
                pn.ipgpIpg(),
                pn.ipgpNum(),
                pn.ipgpCstAgPn(),
                pn.cstAgPnCode(),
                pn.ipgpSmTtl(),
                pn.ipgpSmWrk(),
                pn.ipgpSmEqu(),
                pn.ipgpSmOth(),
                pn.ipgpSmAgFee(),
                pn.ipgpCostAdjust(),
                pn.ipgpSmReserv(),
                pn.ipgpTskCms(),
                pn.ipgpSh(),
                pn.ipgpShName()
        );
    }

    private IpgStPnDto toStPnDto(IpgStPn stPn) {
        return new IpgStPnDto(stPn.ipgspKey(), stPn.ipgspPn(), stPn.ipgspSt(), stPn.stName());
    }

    private IpgShDto toShDto(IpgSh sh) {
        return new IpgShDto(sh.ipgsKey(), sh.ipgsNm());
    }

    /**
     * Input создания ИП.
     */
    public record CreateIpgInput(
            Integer ipgOg,
            String ipgNm,
            Integer ipgYy,
            Integer ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            Integer ipgStRlSh,
            Integer ipgYyYear
    ) {
    }

    /**
     * Input обновления ИП.
     */
    public record UpdateIpgInput(
            String ipgNm,
            Integer ipgYy,
            Integer ipgNum,
            LocalDate ipgStr,
            LocalDate ipgEnd,
            Integer ipgRepl,
            Integer ipgStRlSh,
            Integer ipgYyYear
    ) {
    }

    /**
     * Input создания пункта.
     */
    public record CreateIpgPnInput(
            Integer ipgpIpg,
            Integer ipgpNum,
            Integer ipgpCstAgPn,
            Integer ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms
    ) {
    }

    /**
     * Input обновления пункта.
     */
    public record UpdateIpgPnInput(
            Integer ipgpNum,
            Integer ipgpCstAgPn,
            Integer ipgpSh,
            BigDecimal ipgpSmTtl,
            BigDecimal ipgpSmWrk,
            BigDecimal ipgpSmEqu,
            BigDecimal ipgpSmOth,
            BigDecimal ipgpSmAgFee,
            BigDecimal ipgpCostAdjust,
            BigDecimal ipgpSmReserv,
            String ipgpTskCms
    ) {
    }
}
