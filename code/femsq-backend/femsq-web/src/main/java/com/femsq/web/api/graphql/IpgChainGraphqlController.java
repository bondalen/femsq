package com.femsq.web.api.graphql;

import com.femsq.database.service.IpgChainRelationService;
import com.femsq.database.service.IpgChainService;
import com.femsq.database.service.InvestmentPlanGroupService;
import com.femsq.database.service.InvestmentProgramService;
import com.femsq.database.service.StNetworkService;
import com.femsq.web.api.dto.InvestmentPlanGroupLookupDto;
import com.femsq.web.api.dto.InvestmentProgramLookupDto;
import com.femsq.web.api.dto.IpgChainDto;
import com.femsq.web.api.dto.IpgChainRelationDto;
import com.femsq.web.api.dto.StNetworkDto;
import com.femsq.web.api.mapper.IpgChainMapper;
import com.femsq.web.api.mapper.IpgChainRelationMapper;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** GraphQL-контроллер для цепочек инвестиционных программ. */
@Controller
public class IpgChainGraphqlController {

    private final IpgChainService ipgChainService;
    private final IpgChainRelationService relationService;
    private final StNetworkService stNetworkService;
    private final InvestmentProgramService investmentProgramService;
    private final InvestmentPlanGroupService planGroupService;
    private final IpgChainMapper ipgChainMapper;
    private final IpgChainRelationMapper relationMapper;

    public IpgChainGraphqlController(
            IpgChainService ipgChainService,
            IpgChainRelationService relationService,
            StNetworkService stNetworkService,
            InvestmentProgramService investmentProgramService,
            InvestmentPlanGroupService planGroupService,
            IpgChainMapper ipgChainMapper,
            IpgChainRelationMapper relationMapper) {
        this.ipgChainService = ipgChainService;
        this.relationService = relationService;
        this.stNetworkService = stNetworkService;
        this.investmentProgramService = investmentProgramService;
        this.planGroupService = planGroupService;
        this.ipgChainMapper = ipgChainMapper;
        this.relationMapper = relationMapper;
    }

    @QueryMapping
    public List<IpgChainDto> investmentChains(
            @Argument("name") String name,
            @Argument("year") Integer year) {
        var stNetMap = buildStNetworkMap();
        var chains = ipgChainService.getAll(0, Integer.MAX_VALUE, "ipgcKey", "asc", normalize(name), year);
        return ipgChainMapper.toDto(chains, stNetMap);
    }

    @QueryMapping
    public IpgChainDto investmentChain(@Argument("id") int id) {
        return ipgChainService.getById(id)
                .map(chain -> ipgChainMapper.toDto(chain, buildStNetworkMap()))
                .orElse(null);
    }

    @QueryMapping
    public List<IpgChainRelationDto> investmentChainRelations(@Argument("chainId") int chainId) {
        var relations = relationService.getByChain(chainId);
        return relationMapper.toDto(relations, buildIpgMap(), buildPlanGroupMap());
    }

    @QueryMapping
    public List<StNetworkDto> stNetworks() {
        return stNetworkService.getAll().stream()
                .map(item -> new StNetworkDto(item.stnKey(), item.name()))
                .collect(Collectors.toList());
    }

    @QueryMapping
    public List<InvestmentProgramLookupDto> investmentPrograms() {
        return investmentProgramService.getAll().stream()
                .map(item -> new InvestmentProgramLookupDto(item.ipgKey(), item.displayName()))
                .collect(Collectors.toList());
    }

    @QueryMapping
    public List<InvestmentPlanGroupLookupDto> investmentPlanGroups() {
        return planGroupService.getAll().stream()
                .map(item -> new InvestmentPlanGroupLookupDto(item.planGroupKey(), item.displayName()))
                .collect(Collectors.toList());
    }

    private Map<Integer, String> buildStNetworkMap() {
        return stNetworkService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.stnKey(),
                        entry -> entry.name(),
                        (a, b) -> a));
    }

    private Map<Integer, String> buildIpgMap() {
        return investmentProgramService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.ipgKey(),
                        entry -> entry.displayName(),
                        (a, b) -> a));
    }

    private Map<Integer, String> buildPlanGroupMap() {
        return planGroupService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.planGroupKey(),
                        entry -> entry.displayName(),
                        (a, b) -> a));
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
