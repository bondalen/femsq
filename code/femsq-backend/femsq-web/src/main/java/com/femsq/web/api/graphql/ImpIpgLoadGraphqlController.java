package com.femsq.web.api.graphql;

import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgParseResult;
import com.femsq.database.model.ImpIpgPointsApplyResult;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgReconcileResult;
import com.femsq.database.model.ImpIpgReconcileRow;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgShResolveLeaf;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgStiInheritLeaf;
import com.femsq.database.model.ImpIpgStiInheritResult;
import com.femsq.database.service.ImpIpgLoadService;
import com.femsq.database.service.ImpIpgPointsApplyService;
import com.femsq.database.service.ImpIpgPointsGateService;
import com.femsq.database.service.ImpIpgReconcileService;
import com.femsq.database.service.ImpIpgShResolveService;
import com.femsq.database.service.ImpIpgStiInheritService;
import com.femsq.web.api.dto.ImpIpgLoadDto;
import com.femsq.web.api.dto.ImpIpgParseResultDto;
import com.femsq.web.api.dto.ImpIpgPointsApplyResultDto;
import com.femsq.web.api.dto.ImpIpgPointsGateResultDto;
import com.femsq.web.api.dto.ImpIpgReconcileResultDto;
import com.femsq.web.api.dto.ImpIpgReconcileRowDto;
import com.femsq.web.api.dto.ImpIpgRowDto;
import com.femsq.web.api.dto.ImpIpgShResolveLeafDto;
import com.femsq.web.api.dto.ImpIpgShResolveResultDto;
import com.femsq.web.api.dto.ImpIpgStiInheritLeafDto;
import com.femsq.web.api.dto.ImpIpgStiInheritResultDto;
import com.femsq.web.ipg.excel.ImpIpgExcelParseService;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/**
 * GraphQL загрузки годовой ИП: каркас, парсер, сверка, gate / sti / ipgpSh / apply (§3.1.6 / §3.2.1–.4).
 */
@Controller
public class ImpIpgLoadGraphqlController {

    private static final Logger log = Logger.getLogger(ImpIpgLoadGraphqlController.class.getName());

    private final ImpIpgLoadService loadService;
    private final ImpIpgExcelParseService parseService;
    private final ImpIpgReconcileService reconcileService;
    private final ImpIpgPointsGateService pointsGateService;
    private final ImpIpgStiInheritService stiInheritService;
    private final ImpIpgShResolveService shResolveService;
    private final ImpIpgPointsApplyService pointsApplyService;

    public ImpIpgLoadGraphqlController(
            ImpIpgLoadService loadService,
            ImpIpgExcelParseService parseService,
            ImpIpgReconcileService reconcileService,
            ImpIpgPointsGateService pointsGateService,
            ImpIpgStiInheritService stiInheritService,
            ImpIpgShResolveService shResolveService,
            ImpIpgPointsApplyService pointsApplyService) {
        this.loadService = loadService;
        this.parseService = parseService;
        this.reconcileService = reconcileService;
        this.pointsGateService = pointsGateService;
        this.stiInheritService = stiInheritService;
        this.shResolveService = shResolveService;
        this.pointsApplyService = pointsApplyService;
    }

    @QueryMapping
    public List<ImpIpgLoadDto> impIpgLoads(@Argument("ipgKey") int ipgKey) {
        return loadService.listLoadsByIpg(ipgKey).stream().map(this::toLoadDto).collect(Collectors.toList());
    }

    @QueryMapping
    public ImpIpgLoadDto impIpgLoad(@Argument("id") int id) {
        return loadService.getLoad(id).map(this::toLoadDto).orElse(null);
    }

    @QueryMapping
    public List<ImpIpgRowDto> impIpgRows(
            @Argument("loadKey") int loadKey,
            @Argument("structureOnly") Boolean structureOnly) {
        List<ImpIpgRow> rows = Boolean.TRUE.equals(structureOnly)
                ? loadService.listStructureRows(loadKey)
                : loadService.listRows(loadKey);
        return rows.stream().map(this::toRowDto).collect(Collectors.toList());
    }

    @QueryMapping
    public ImpIpgRowDto impIpgRow(@Argument("id") int id) {
        return loadService.getRow(id).map(this::toRowDto).orElse(null);
    }

    @MutationMapping
    public ImpIpgLoadDto createImpIpgLoad(@Argument("input") CreateImpIpgLoadInput input) {
        log.info(() -> "createImpIpgLoad ipg=" + input.ipgKey());
        return toLoadDto(loadService.createLoad(input.ipgKey(), input.name(), input.filePath(), input.note()));
    }

    @MutationMapping
    public ImpIpgLoadDto updateImpIpgLoad(
            @Argument("id") int id,
            @Argument("input") UpdateImpIpgLoadInput input) {
        return toLoadDto(loadService.updateLoad(id, input.name(), input.filePath(), input.note()));
    }

    @MutationMapping
    public Boolean deleteImpIpgLoad(@Argument("id") int id) {
        return loadService.deleteLoad(id);
    }

    @MutationMapping
    public ImpIpgRowDto createImpIpgRow(@Argument("input") CreateImpIpgRowInput input) {
        return toRowDto(loadService.createRow(
                input.loadKey(),
                input.rowNo(),
                input.rowKind(),
                input.text(),
                input.parentKey(),
                input.stiKey(),
                input.ctx()));
    }

    @MutationMapping
    public ImpIpgRowDto updateImpIpgRow(
            @Argument("id") int id,
            @Argument("input") UpdateImpIpgRowInput input) {
        return toRowDto(loadService.updateRow(
                id,
                input.rowNo(),
                input.rowKind(),
                input.text(),
                input.parentKey(),
                input.stiKey(),
                Boolean.TRUE.equals(input.clearStiKey()),
                input.ctx()));
    }

    @MutationMapping
    public Boolean deleteImpIpgRow(@Argument("id") int id) {
        return loadService.deleteRow(id);
    }

    @MutationMapping
    public Integer clearImpIpgRows(@Argument("loadKey") int loadKey) {
        return loadService.clearRows(loadKey);
    }

    @MutationMapping
    public ImpIpgParseResultDto parseImpIpgLoad(
            @Argument("id") int id,
            @Argument("filePath") String filePath) {
        log.info(() -> "parseImpIpgLoad id=" + id + " filePath=" + filePath);
        ImpIpgParseResult result = parseService.parseLoad(id, filePath);
        return new ImpIpgParseResultDto(
                result.loadKey(),
                result.sheetName(),
                result.filePath(),
                result.sectionCount(),
                result.leafCount(),
                result.totalRows());
    }

    @QueryMapping
    public ImpIpgReconcileResultDto impIpgStructureReconcile(
            @Argument("loadKey") int loadKey,
            @Argument("stNetKey") int stNetKey) {
        return toReconcileDto(reconcileService.reconcile(loadKey, stNetKey, false));
    }

    /**
     * Gate §3.2.1: готовность сессии к загрузке пунктов.
     */
    @QueryMapping
    public ImpIpgPointsGateResultDto impIpgPointsGate(@Argument("loadKey") int loadKey) {
        log.info(() -> "impIpgPointsGate load=" + loadKey);
        return toGateDto(pointsGateService.evaluate(loadKey));
    }

    /**
     * §3.2.2: превью наследования sti L←S (дыры без записи).
     */
    @QueryMapping
    public ImpIpgStiInheritResultDto impIpgStiInherit(@Argument("loadKey") int loadKey) {
        log.info(() -> "impIpgStiInherit load=" + loadKey);
        return toStiInheritDto(stiInheritService.evaluate(loadKey));
    }

    /**
     * §3.2.3: превью резолва {@code ipgpSh} (без записи в домен).
     */
    @QueryMapping
    public ImpIpgShResolveResultDto impIpgShResolve(
            @Argument("loadKey") int loadKey,
            @Argument("previousIpgKey") Integer previousIpgKey) {
        log.info(() -> "impIpgShResolve load=" + loadKey + " prev=" + previousIpgKey);
        return toShResolveDto(shResolveService.evaluate(loadKey, previousIpgKey));
    }

    @MutationMapping
    public ImpIpgReconcileResultDto reconcileImpIpgStructure(
            @Argument("loadKey") int loadKey,
            @Argument("stNetKey") int stNetKey,
            @Argument("persistMatches") Boolean persistMatches) {
        boolean persist = persistMatches == null || persistMatches;
        log.info(() -> "reconcileImpIpgStructure load=" + loadKey
                + " stNet=" + stNetKey + " persist=" + persist);
        return toReconcileDto(reconcileService.reconcile(loadKey, stNetKey, persist));
    }

    @MutationMapping
    public ImpIpgRowDto mapImpIpgRowSti(
            @Argument("id") int id,
            @Argument("stiKey") Integer stiKey,
            @Argument("clearStiKey") Boolean clearStiKey) {
        boolean clear = Boolean.TRUE.equals(clearStiKey);
        return toRowDto(loadService.updateRow(id, null, null, null, null, stiKey, clear, null));
    }

    /**
     * §3.2.4: bulk apply листьев → ipgPn+ipgStPn. {@code dryRun} по умолчанию false.
     */
    @MutationMapping
    public ImpIpgPointsApplyResultDto applyImpIpgPoints(
            @Argument("loadKey") int loadKey,
            @Argument("previousIpgKey") Integer previousIpgKey,
            @Argument("dryRun") Boolean dryRun) {
        boolean dry = Boolean.TRUE.equals(dryRun);
        log.info(() -> "applyImpIpgPoints load=" + loadKey + " prev=" + previousIpgKey + " dryRun=" + dry);
        return toApplyDto(pointsApplyService.apply(loadKey, previousIpgKey, dry));
    }

    private ImpIpgPointsApplyResultDto toApplyDto(ImpIpgPointsApplyResult result) {
        return new ImpIpgPointsApplyResultDto(
                result.loadKey(),
                result.ipgKey(),
                result.previousIpgKey(),
                result.dryRun(),
                result.leafCount(),
                result.appliedCount(),
                result.skippedAlreadyCount(),
                result.ready(),
                result.errors(),
                result.problemRowIds(),
                result.createdPnKeys());
    }

    private ImpIpgPointsGateResultDto toGateDto(ImpIpgPointsGateResult result) {
        return new ImpIpgPointsGateResultDto(
                result.loadKey(),
                result.ipgKey(),
                result.stNetKey(),
                result.sectionCount(),
                result.openCount(),
                result.ready(),
                result.errors(),
                result.openRowIds());
    }

    private ImpIpgStiInheritResultDto toStiInheritDto(ImpIpgStiInheritResult result) {
        List<ImpIpgStiInheritLeafDto> holes = result.holes().stream()
                .map(this::toStiInheritLeafDto)
                .collect(Collectors.toList());
        return new ImpIpgStiInheritResultDto(
                result.loadKey(),
                result.ipgKey(),
                result.leafCount(),
                result.readyCount(),
                result.holeCount(),
                result.ready(),
                result.errors(),
                holes);
    }

    private ImpIpgStiInheritLeafDto toStiInheritLeafDto(ImpIpgStiInheritLeaf leaf) {
        return new ImpIpgStiInheritLeafDto(
                leaf.rowId(),
                leaf.rowNo(),
                leaf.text(),
                leaf.parentKey(),
                leaf.resolvedStiKey(),
                leaf.holeReason());
    }

    private ImpIpgShResolveResultDto toShResolveDto(ImpIpgShResolveResult result) {
        List<ImpIpgShResolveLeafDto> problems = result.problemLeaves().stream()
                .map(this::toShResolveLeafDto)
                .collect(Collectors.toList());
        return new ImpIpgShResolveResultDto(
                result.loadKey(),
                result.ipgKey(),
                result.previousIpgKey(),
                result.leafCount(),
                result.resolvedCount(),
                result.errorCount(),
                result.fromPrevCount(),
                result.default4Count(),
                result.freePoolCount(),
                result.ready(),
                result.errors(),
                problems);
    }

    private ImpIpgShResolveLeafDto toShResolveLeafDto(ImpIpgShResolveLeaf leaf) {
        return new ImpIpgShResolveLeafDto(
                leaf.rowId(),
                leaf.rowNo(),
                leaf.text(),
                leaf.cstAgPnCode(),
                leaf.resolvedSh(),
                leaf.source() == null ? null : leaf.source().name(),
                leaf.errorReason());
    }

    private ImpIpgReconcileResultDto toReconcileDto(ImpIpgReconcileResult result) {
        List<ImpIpgReconcileRowDto> rows = result.rows().stream()
                .map(this::toReconcileRowDto)
                .collect(Collectors.toList());
        return new ImpIpgReconcileResultDto(
                result.loadKey(),
                result.stNetKey(),
                result.matched(),
                result.open(),
                rows);
    }

    private ImpIpgReconcileRowDto toReconcileRowDto(ImpIpgReconcileRow row) {
        return new ImpIpgReconcileRowDto(
                row.rowId(),
                row.rowNo(),
                row.text(),
                row.stiKey(),
                row.status().name(),
                row.candidateStiKeys(),
                row.pathMatched(),
                row.nameInPool(),
                row.closed());
    }

    private ImpIpgLoadDto toLoadDto(ImpIpgLoad load) {
        return new ImpIpgLoadDto(
                load.iilKey(),
                load.iilIpg(),
                load.iilNm(),
                load.iilFilePath(),
                load.iilNote(),
                load.iilCreated() != null ? load.iilCreated().toString() : null);
    }

    private ImpIpgRowDto toRowDto(ImpIpgRow row) {
        return new ImpIpgRowDto(
                row.iiKey(),
                row.iiLoad(),
                row.iiRowNo(),
                row.iiRowKind(),
                row.iiText(),
                row.iiParent(),
                row.iiStiKey(),
                row.iiCtx());
    }

    public record CreateImpIpgLoadInput(int ipgKey, String name, String filePath, String note) {
    }

    public record UpdateImpIpgLoadInput(String name, String filePath, String note) {
    }

    public record CreateImpIpgRowInput(
            int loadKey,
            int rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            String ctx) {
    }

    public record UpdateImpIpgRowInput(
            Integer rowNo,
            String rowKind,
            String text,
            Integer parentKey,
            Integer stiKey,
            Boolean clearStiKey,
            String ctx) {
    }
}
