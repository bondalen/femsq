package com.femsq.web.api.graphql;

import com.femsq.database.model.ImpIpgLoadMonf;
import com.femsq.database.model.ImpIpgMonfApplyResult;
import com.femsq.database.model.ImpIpgMonfParseResult;
import com.femsq.database.model.ImpIpgMonfParseRow;
import com.femsq.database.service.ImpIpgLoadMonfService;
import com.femsq.web.api.dto.ImpIpgLoadMonfDto;
import com.femsq.web.api.dto.ImpIpgMonfApplyResultDto;
import com.femsq.web.api.dto.ImpIpgMonfParseResultDto;
import com.femsq.web.api.dto.ImpIpgMonfParseRowDto;
import com.femsq.web.ipg.excel.ImpIpgLoadMonfApplyService;
import com.femsq.web.ipg.excel.ImpIpgLoadMonfParseService;
import java.math.BigDecimal;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/**
 * GraphQL CRUD + parse {@code impIpgLoadMonf} (C2 §6.4–6.5 LdM).
 */
@Controller
public class ImpIpgLoadMonfGraphqlController {

    private static final Logger log = Logger.getLogger(ImpIpgLoadMonfGraphqlController.class.getName());

    private final ImpIpgLoadMonfService monfService;
    private final ImpIpgLoadMonfParseService parseService;
    private final ImpIpgLoadMonfApplyService applyService;

    public ImpIpgLoadMonfGraphqlController(
            ImpIpgLoadMonfService monfService,
            ImpIpgLoadMonfParseService parseService,
            ImpIpgLoadMonfApplyService applyService) {
        this.monfService = monfService;
        this.parseService = parseService;
        this.applyService = applyService;
    }

    @QueryMapping
    public List<ImpIpgLoadMonfDto> impIpgLoadMonfs(@Argument("ipgKey") int ipgKey) {
        return monfService.listByIpg(ipgKey).stream().map(this::toDto).collect(Collectors.toList());
    }

    @QueryMapping
    public List<ImpIpgLoadMonfDto> impIpgLoadMonfsByLoad(@Argument("loadKey") int loadKey) {
        return monfService.listByLoad(loadKey).stream().map(this::toDto).collect(Collectors.toList());
    }

    @QueryMapping
    public ImpIpgLoadMonfDto impIpgLoadMonf(@Argument("id") int id) {
        return monfService.get(id).map(this::toDto).orElse(null);
    }

    @MutationMapping
    public ImpIpgLoadMonfDto createImpIpgLoadMonf(@Argument("input") CreateImpIpgLoadMonfInput input) {
        log.info(() -> "createImpIpgLoadMonf load=" + input.loadKey());
        boolean quarter = input.quarter() == null || input.quarter();
        return toDto(monfService.create(
                input.loadKey(),
                input.utPlKey(),
                input.name(),
                input.filePath(),
                input.sheet(),
                input.limColumn(),
                quarter,
                input.sumFirst(),
                input.note()));
    }

    @MutationMapping
    public ImpIpgLoadMonfDto updateImpIpgLoadMonf(
            @Argument("id") int id,
            @Argument("input") UpdateImpIpgLoadMonfInput input) {
        boolean quarter = input.quarter() == null || input.quarter();
        return toDto(monfService.update(
                id,
                input.utPlKey(),
                input.name(),
                input.filePath(),
                input.sheet(),
                input.limColumn(),
                quarter,
                input.sumFirst(),
                input.note()));
    }

    @MutationMapping
    public Boolean deleteImpIpgLoadMonf(@Argument("id") int id) {
        return monfService.delete(id);
    }

    @MutationMapping
    public ImpIpgMonfParseResultDto parseImpIpgLoadMonf(
            @Argument("id") int id,
            @Argument("filePath") String filePath) {
        log.info(() -> "parseImpIpgLoadMonf id=" + id + " filePath=" + filePath);
        return toParseDto(parseService.parse(id, filePath));
    }

    @MutationMapping
    public ImpIpgMonfApplyResultDto applyImpIpgLoadMonf(
            @Argument("id") int id,
            @Argument("dryRun") Boolean dryRun) {
        boolean dry = Boolean.TRUE.equals(dryRun);
        log.info(() -> "applyImpIpgLoadMonf id=" + id + " dryRun=" + dry);
        return toApplyDto(applyService.apply(id, dry));
    }

    private ImpIpgMonfApplyResultDto toApplyDto(ImpIpgMonfApplyResult result) {
        return new ImpIpgMonfApplyResultDto(
                result.monfKey(),
                result.utPlKey(),
                result.ipgKey(),
                result.dryRun(),
                result.parsedCount(),
                result.appliedCount(),
                result.unmatchedCount(),
                result.ambiguousCount(),
                result.errorCount(),
                result.problems(),
                result.logHtml());
    }

    private ImpIpgMonfParseResultDto toParseDto(ImpIpgMonfParseResult result) {
        List<ImpIpgMonfParseRowDto> rows = result.rows().stream()
                .map(this::toParseRowDto)
                .collect(Collectors.toList());
        return new ImpIpgMonfParseResultDto(
                result.monfKey(),
                result.sheetName(),
                result.filePath(),
                result.codeColumn(),
                result.limColumn(),
                result.quarter(),
                result.sumFirst(),
                result.codeHits(),
                result.loadedCount(),
                result.skippedCount(),
                rows,
                result.logHtml());
    }

    private ImpIpgMonfParseRowDto toParseRowDto(ImpIpgMonfParseRow row) {
        return new ImpIpgMonfParseRowDto(
                row.rowNo(),
                row.cstCode(),
                row.name(),
                toDouble(row.limYear()),
                row.quarters().stream().map(this::toDouble).collect(Collectors.toList()),
                row.months().stream().map(this::toDouble).collect(Collectors.toList()),
                row.skipped(),
                row.skipReason());
    }

    private Double toDouble(BigDecimal value) {
        return value == null ? null : value.doubleValue();
    }

    private ImpIpgLoadMonfDto toDto(ImpIpgLoadMonf row) {
        return new ImpIpgLoadMonfDto(
                row.iilmKey(),
                row.iilmLoad(),
                row.iilmUtPl(),
                row.iilmNm(),
                row.iilmFilePath(),
                row.iilmSheet(),
                row.iilmLimColumn(),
                row.iilmQuarter(),
                row.iilmSumFirst(),
                row.iilmNote(),
                row.iilmCreated() != null ? row.iilmCreated().toString() : null,
                row.iilmResults());
    }

    public record CreateImpIpgLoadMonfInput(
            int loadKey,
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            Boolean quarter,
            Integer sumFirst,
            String note) {
    }

    public record UpdateImpIpgLoadMonfInput(
            Integer utPlKey,
            String name,
            String filePath,
            String sheet,
            String limColumn,
            Boolean quarter,
            Integer sumFirst,
            String note) {
    }
}
