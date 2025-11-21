package com.femsq.web.api.rest;

import com.femsq.database.service.InvestmentPlanGroupService;
import com.femsq.database.service.InvestmentProgramService;
import com.femsq.database.service.StNetworkService;
import com.femsq.web.api.dto.InvestmentPlanGroupLookupDto;
import com.femsq.web.api.dto.InvestmentProgramLookupDto;
import com.femsq.web.api.dto.StNetworkDto;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** REST-контроллер для lookup-справочников. */
@RestController
@RequestMapping("/api/v1/lookups")
public class LookupRestController {

    private static final Logger log = Logger.getLogger(LookupRestController.class.getName());

    private final StNetworkService stNetworkService;
    private final InvestmentProgramService investmentProgramService;
    private final InvestmentPlanGroupService planGroupService;

    public LookupRestController(
            StNetworkService stNetworkService,
            InvestmentProgramService investmentProgramService,
            InvestmentPlanGroupService planGroupService) {
        this.stNetworkService = stNetworkService;
        this.investmentProgramService = investmentProgramService;
        this.planGroupService = planGroupService;
    }

    @GetMapping("/st-networks")
    public List<StNetworkDto> getStNetworks() {
        log.info("Handling GET /api/v1/lookups/st-networks");
        return stNetworkService.getAll().stream()
                .map(item -> new StNetworkDto(item.stnKey(), item.name()))
                .collect(Collectors.toList());
    }

    @GetMapping("/investment-programs")
    public List<InvestmentProgramLookupDto> getInvestmentPrograms() {
        log.info("Handling GET /api/v1/lookups/investment-programs");
        return investmentProgramService.getAll().stream()
                .map(item -> new InvestmentProgramLookupDto(item.ipgKey(), item.displayName()))
                .collect(Collectors.toList());
    }

    @GetMapping("/plan-groups")
    public List<InvestmentPlanGroupLookupDto> getPlanGroups() {
        log.info("Handling GET /api/v1/lookups/plan-groups");
        return planGroupService.getAll().stream()
                .map(item -> new InvestmentPlanGroupLookupDto(item.planGroupKey(), item.displayName()))
                .collect(Collectors.toList());
    }
}
