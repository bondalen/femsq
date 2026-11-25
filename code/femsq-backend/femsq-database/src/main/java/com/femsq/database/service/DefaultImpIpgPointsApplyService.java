package com.femsq.database.service;

import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.CstAgPn;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgPointsApplyResult;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgShResolveLeaf;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgStiInheritLeaf;
import com.femsq.database.model.ImpIpgStiInheritResult;
import com.femsq.database.model.IpgFull;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgPnBulkDraft;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Apply пунктов из staging (§3.2.4 / §3.2.7 partial).
 *
 * <p>Ошибка строки → лог + skip; успешные пишутся (TX на один лист).
 * Уже есть unique {@code (ipg,cstAgPn,sh)} → skip OK (идемпотентный повтор).
 * Жёсткий отказ всего прохода — только нет сессии / ipg / {@code ipgStRlSh}.
 */
public class DefaultImpIpgPointsApplyService implements ImpIpgPointsApplyService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgPointsApplyService.class.getName());

    static final String ERR_CSTAGPN_MISSING = "CSTAGPN_NOT_FOUND";
    static final String ERR_STI_HOLE = "STI_HOLE";
    static final String ERR_SH = "SH_RESOLVE";
    static final String SKIP_ALREADY = "ALREADY_EXISTS";

    private static final Pattern NNN_FIELD =
            Pattern.compile("\"nnn\"\\s*:\\s*\"([^\"]*)\"");
    private static final Pattern COMMISSIONING_FIELD =
            Pattern.compile("\"commissioning\"\\s*:\\s*\"([^\"]*)\"");

    private final ImpIpgLoadDao loadDao;
    private final IpgLeavesDao ipgLeavesDao;
    private final CstAgPnDao cstAgPnDao;
    private final ImpIpgPointsGateService gateService;
    private final ImpIpgStiInheritService stiInheritService;
    private final ImpIpgShResolveService shResolveService;

    /**
     * @param loadDao           staging
     * @param ipgLeavesDao      домен ipgPn/ipgStPn
     * @param cstAgPnDao        lookup САК по коду
     * @param gateService       §3.2.1 (мягкий: только ipgStRlSh обязателен)
     * @param stiInheritService §3.2.2
     * @param shResolveService  §3.2.3
     */
    public DefaultImpIpgPointsApplyService(
            ImpIpgLoadDao loadDao,
            IpgLeavesDao ipgLeavesDao,
            CstAgPnDao cstAgPnDao,
            ImpIpgPointsGateService gateService,
            ImpIpgStiInheritService stiInheritService,
            ImpIpgShResolveService shResolveService) {
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
        this.ipgLeavesDao = Objects.requireNonNull(ipgLeavesDao, "ipgLeavesDao");
        this.cstAgPnDao = Objects.requireNonNull(cstAgPnDao, "cstAgPnDao");
        this.gateService = Objects.requireNonNull(gateService, "gateService");
        this.stiInheritService = Objects.requireNonNull(stiInheritService, "stiInheritService");
        this.shResolveService = Objects.requireNonNull(shResolveService, "shResolveService");
    }

    @Override
    public ImpIpgPointsApplyResult apply(int loadKey, Integer previousIpgKey, boolean dryRun) {
        log.info(() -> "pointsApply(partial) load=" + loadKey + " prev=" + previousIpgKey + " dryRun=" + dryRun);
        List<String> errors = new ArrayList<>();
        List<Integer> problemRowIds = new ArrayList<>();

        ImpIpgLoad load = loadDao.findLoadByKey(loadKey).orElse(null);
        if (load == null) {
            errors.add("Сессия impIpgLoad не найдена: " + loadKey);
            return fail(loadKey, 0, previousIpgKey, dryRun, 0, errors, problemRowIds);
        }
        int ipgKey = load.iilIpg();

        IpgFull ipg = ipgLeavesDao.findIpgByKey(ipgKey).orElse(null);
        if (ipg == null) {
            errors.add("Карточка ipg не найдена: " + ipgKey);
            return fail(loadKey, ipgKey, previousIpgKey, dryRun, 0, errors, problemRowIds);
        }
        if (ipg.ipgStRlSh() <= 0) {
            errors.add("У ipg=" + ipgKey + " не задан ipgStRlSh (схема структуры)");
            return fail(loadKey, ipgKey, previousIpgKey, dryRun, 0, errors, problemRowIds);
        }

        ImpIpgPointsGateResult gate = gateService.evaluate(loadKey);
        if (gate.openCount() > 0) {
            log.info(() -> "pointsApply gate soft-open load=" + loadKey
                    + " open=" + gate.openCount() + "/" + gate.sectionCount());
        }

        ImpIpgStiInheritResult sti = stiInheritService.evaluate(loadKey);
        ImpIpgShResolveResult sh = shResolveService.evaluate(loadKey, previousIpgKey);

        Map<Integer, ImpIpgRow> rowsByKey = new HashMap<>();
        List<ImpIpgRow> leaves = new ArrayList<>();
        for (ImpIpgRow row : loadDao.findRowsByLoad(loadKey)) {
            rowsByKey.put(row.iiKey(), row);
            if ("L".equalsIgnoreCase(row.iiRowKind())) {
                leaves.add(row);
            }
        }
        leaves.sort(Comparator.comparingInt(ImpIpgRow::iiRowNo).thenComparingInt(ImpIpgRow::iiKey));
        int leafCount = leaves.size();
        if (leafCount == 0) {
            errors.add("В сессии нет листьев (iiRowKind=L); выполните разбор Excel");
            return fail(loadKey, ipgKey, previousIpgKey, dryRun, 0, errors, problemRowIds);
        }

        Map<Integer, ImpIpgStiInheritLeaf> stiByRow = new HashMap<>();
        for (ImpIpgStiInheritLeaf leaf : sti.readyLeaves()) {
            stiByRow.put(leaf.rowId(), leaf);
        }
        for (ImpIpgStiInheritLeaf leaf : sti.holes()) {
            stiByRow.put(leaf.rowId(), leaf);
        }

        Map<Integer, ImpIpgShResolveLeaf> shByRow = new HashMap<>();
        for (ImpIpgShResolveLeaf leaf : sh.resolvedLeaves()) {
            shByRow.put(leaf.rowId(), leaf);
        }
        for (ImpIpgShResolveLeaf leaf : sh.problemLeaves()) {
            shByRow.put(leaf.rowId(), leaf);
        }

        Set<String> existingUnique = new HashSet<>();
        for (IpgPn pn : ipgLeavesDao.findPnsByIpg(ipgKey)) {
            existingUnique.add(uniqueKey(pn.ipgpCstAgPn(), pn.ipgpSh()));
        }

        List<IpgPnBulkDraft> drafts = new ArrayList<>();
        int skippedAlready = 0;

        for (ImpIpgRow leaf : leaves) {
            int rowId = leaf.iiKey();
            ImpIpgStiInheritLeaf stiLeaf = stiByRow.get(rowId);
            if (stiLeaf == null || !stiLeaf.ready()) {
                String reason = stiLeaf == null ? "NO_STI_RESULT" : stiLeaf.holeReason();
                addError(errors, problemRowIds, rowId,
                        ERR_STI_HOLE + " row=" + rowId + " reason=" + reason);
                continue;
            }
            ImpIpgShResolveLeaf shLeaf = shByRow.get(rowId);
            if (shLeaf == null || !shLeaf.ok()) {
                String reason = shLeaf == null ? "NO_SH_RESULT" : shLeaf.errorReason();
                addError(errors, problemRowIds, rowId,
                        ERR_SH + " row=" + rowId + " reason=" + reason);
                continue;
            }
            String code = shLeaf.cstAgPnCode();
            if (code == null || code.isBlank()) {
                addError(errors, problemRowIds, rowId, ERR_CSTAGPN_MISSING + " row=" + rowId);
                continue;
            }
            CstAgPn cstAgPn = cstAgPnDao.findByCodeExact(code).orElse(null);
            if (cstAgPn == null || cstAgPn.cstapKey() == null) {
                addError(errors, problemRowIds, rowId,
                        ERR_CSTAGPN_MISSING + " code=" + code + " row=" + rowId);
                continue;
            }
            int shKey = shLeaf.resolvedSh();
            String uk = uniqueKey(cstAgPn.cstapKey(), shKey);
            if (existingUnique.contains(uk)) {
                skippedAlready++;
                continue;
            }
            String ctx = leaf.iiCtx();
            drafts.add(new IpgPnBulkDraft(
                    rowId,
                    extractNnn(ctx),
                    cstAgPn.cstapKey(),
                    shKey,
                    extractDecimal(ctx, "ttl"),
                    extractDecimal(ctx, "work"),
                    extractDecimal(ctx, "equip"),
                    extractDecimal(ctx, "others"),
                    extractCommissioning(ctx),
                    stiLeaf.resolvedStiKey()));
            existingUnique.add(uk);
        }

        if (dryRun) {
            boolean ready = errors.isEmpty();
            final int wouldApply = drafts.size();
            final int skippedDry = skippedAlready;
            log.info(() -> "pointsApply dryRun load=" + loadKey
                    + " wouldApply=" + wouldApply
                    + " skippedAlready=" + skippedDry
                    + " errors=" + errors.size());
            return new ImpIpgPointsApplyResult(
                    loadKey, ipgKey, previousIpgKey, true, leafCount, wouldApply,
                    skippedDry, ready, errors, problemRowIds, List.of());
        }

        List<Integer> created = new ArrayList<>();
        for (IpgPnBulkDraft draft : drafts) {
            try {
                int pnKey = ipgLeavesDao.createPnWithSt(ipgKey, draft);
                created.add(pnKey);
            } catch (IllegalStateException ex) {
                String message = ex.getMessage() == null ? "" : ex.getMessage();
                if (message.contains("unique") || message.contains("Дубликат") || message.contains("уже")) {
                    skippedAlready++;
                    log.info(() -> "pointsApply race/already stagingRow=" + draft.stagingRowId()
                            + " msg=" + message);
                } else {
                    addError(errors, problemRowIds, draft.stagingRowId(),
                            "INSERT_FAIL row=" + draft.stagingRowId() + " " + message);
                }
            } catch (DaoException ex) {
                addError(errors, problemRowIds, draft.stagingRowId(),
                        "INSERT_FAIL row=" + draft.stagingRowId() + " " + ex.getMessage());
            }
        }

        boolean ready = errors.isEmpty();
        final int applied = created.size();
        final int skipped = skippedAlready;
        log.info(() -> "pointsApply committed load=" + loadKey + " ipg=" + ipgKey
                + " applied=" + applied + " skippedAlready=" + skipped
                + " errors=" + errors.size() + " ready=" + ready);
        return new ImpIpgPointsApplyResult(
                loadKey, ipgKey, previousIpgKey, false, leafCount, applied,
                skippedAlready, ready, errors, problemRowIds, created);
    }

    private static String uniqueKey(int cstAgPnKey, int sh) {
        return cstAgPnKey + "|" + sh;
    }

    private static void addError(
            List<String> errors, List<Integer> problemRowIds, int rowId, String message) {
        errors.add(message);
        problemRowIds.add(rowId);
    }

    static Integer extractNnn(String ctx) {
        if (ctx == null || ctx.isBlank()) {
            return null;
        }
        Matcher matcher = NNN_FIELD.matcher(ctx);
        if (!matcher.find()) {
            return null;
        }
        String raw = matcher.group(1).trim();
        if (raw.isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(raw.replaceAll("[^0-9-]", ""));
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    static BigDecimal extractDecimal(String ctx, String field) {
        if (ctx == null || ctx.isBlank()) {
            return null;
        }
        Pattern pattern = Pattern.compile(String.format(
                "\"%s\"\\s*:\\s*(-?[0-9]+(?:\\.[0-9]+)?)",
                Pattern.quote(field)));
        Matcher matcher = pattern.matcher(ctx);
        if (!matcher.find()) {
            return null;
        }
        try {
            return new BigDecimal(matcher.group(1));
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    static String extractCommissioning(String ctx) {
        if (ctx == null || ctx.isBlank()) {
            return null;
        }
        Matcher matcher = COMMISSIONING_FIELD.matcher(ctx);
        if (!matcher.find()) {
            return null;
        }
        String value = matcher.group(1).trim();
        return value.isEmpty() ? null : value;
    }

    private static ImpIpgPointsApplyResult fail(
            int loadKey,
            int ipgKey,
            Integer previousIpgKey,
            boolean dryRun,
            int leafCount,
            List<String> errors,
            List<Integer> problemRowIds) {
        return new ImpIpgPointsApplyResult(
                loadKey, ipgKey, previousIpgKey, dryRun, leafCount, 0, 0,
                false, errors, problemRowIds, List.of());
    }
}
