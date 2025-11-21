package com.femsq.web.api.rest;

import com.femsq.database.service.IpgChainRelationService;
import com.femsq.database.service.IpgChainService;
import com.femsq.database.service.InvestmentPlanGroupService;
import com.femsq.database.service.InvestmentProgramService;
import com.femsq.database.service.StNetworkService;
import com.femsq.web.api.dto.IpgChainDto;
import com.femsq.web.api.dto.IpgChainRelationDto;
import com.femsq.web.api.dto.PageResponse;
import com.femsq.web.api.mapper.IpgChainMapper;
import com.femsq.web.api.mapper.IpgChainRelationMapper;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** REST-контроллер для цепочек инвестиционных программ. */
@RestController
@RequestMapping("/api/v1/ipg-chains")
public class IpgChainRestController {

    private static final Logger log = Logger.getLogger(IpgChainRestController.class.getName());

    private final IpgChainService ipgChainService;
    private final IpgChainRelationService relationService;
    private final StNetworkService stNetworkService;
    private final InvestmentProgramService investmentProgramService;
    private final InvestmentPlanGroupService planGroupService;
    private final IpgChainMapper ipgChainMapper;
    private final IpgChainRelationMapper relationMapper;

    public IpgChainRestController(
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

    @GetMapping
    public PageResponse<IpgChainDto> getChains(
            @RequestParam(required = false, defaultValue = "0") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Integer year) {
        log.info(() -> String.format("Handling GET /api/v1/ipg-chains?page=%s&size=%s&sort=%s&name=%s&year=%s",
                page, size, sort, name, year));
        int pageNum = page != null && page >= 0 ? page : 0;
        int pageSize = size != null && size > 0 ? size : 10;
        SortParams sortParams = parseSort(sort);

        var chains = ipgChainService.getAll(pageNum, pageSize, sortParams.field(), sortParams.direction(),
                normalize(name), year);
        long total = ipgChainService.count(normalize(name), year);
        Map<Integer, String> stNetNames = buildStNetworkMap();
        List<IpgChainDto> content = ipgChainMapper.toDto(chains, stNetNames);
        return PageResponse.of(content, pageNum, pageSize, (int) total);
    }

    @GetMapping("/{chainKey}")
    public IpgChainDto getChain(@PathVariable("chainKey") int chainKey) {
        log.info(() -> "Handling GET /api/v1/ipg-chains/" + chainKey);
        return ipgChainService.getById(chainKey)
                .map(chain -> ipgChainMapper.toDto(chain, buildStNetworkMap()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Цепочка не найдена"));
    }

    @GetMapping("/{chainKey}/relations")
    public List<IpgChainRelationDto> getRelations(@PathVariable("chainKey") int chainKey) {
        log.info(() -> "Handling GET /api/v1/ipg-chains/" + chainKey + "/relations");
        var relations = relationService.getByChain(chainKey);
        Map<Integer, String> ipgNames = investmentProgramService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.ipgKey(),
                        entry -> entry.displayName(),
                        (a, b) -> a));
        Map<Integer, String> planGroupNames = planGroupService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.planGroupKey(),
                        entry -> entry.displayName(),
                        (a, b) -> a));
        return relationMapper.toDto(relations, ipgNames, planGroupNames);
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private Map<Integer, String> buildStNetworkMap() {
        return stNetworkService.getAll().stream()
                .collect(Collectors.toMap(
                        entry -> entry.stnKey(),
                        entry -> entry.name(),
                        (a, b) -> a));
    }

    private SortParams parseSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return new SortParams("ipgcKey", "asc");
        }
        String[] parts = sort.split(",");
        String field = parts.length > 0 && !parts[0].isBlank() ? parts[0].trim() : "ipgcKey";
        String direction = parts.length > 1 ? parts[1].trim().toLowerCase() : "asc";
        if (!"desc".equals(direction)) {
            direction = "asc";
        }
        return new SortParams(field, direction);
    }

    private record SortParams(String field, String direction) {}
}
