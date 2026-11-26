package com.femsq.database.service;

import com.femsq.database.dao.CstAgPnDao;
import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.ipglog.ImpIpgLoadLogContext;
import com.femsq.database.ipglog.ImpIpgLoadLogScope;
import com.femsq.database.ipglog.ImpIpgLoadLogSupport;
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
import com.femsq.database.util.AggAxis;
import com.femsq.database.util.AggAxisKind;
import com.femsq.database.util.AggAxisResult;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static com.femsq.database.ipglog.ImpIpgLoadLogCodes.*;
import static com.femsq.database.ipglog.ImpIpgLoadLogLevel.*;

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
    static final String ERR_INSERT_FAIL = "INSERT_FAIL";
    static final String ERR_AGG_BLOCK = "AGG_BLOCK";

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
        Map<String, List<String>> errorsByCode = new LinkedHashMap<>();

        ImpIpgLoad load = loadDao.findLoadByKey(loadKey).orElse(null);
        ImpIpgLoadLogContext logCtx = new ImpIpgLoadLogContext(loadKey);
        String previousHtml = load == null ? null : load.iilResults();
        String loadSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.LOAD, IPG_LOAD_START,
                "<b>Загрузка пунктов ИП</b>: сессия " + loadKey
                        + (dryRun ? " — <i>проверка (dry-run)</i>" : ""),
                Map.of("loadKey", String.valueOf(loadKey), "dryRun", String.valueOf(dryRun)));
        if (load == null) {
            errors.add("Сессия impIpgLoad не найдена: " + loadKey);
            return fail(logCtx, loadSpan, previousHtml, false, loadKey, 0, previousIpgKey, dryRun, 0,
                    errors, problemRowIds);
        }
        int ipgKey = load.iilIpg();
        boolean persist = !dryRun;

        IpgFull ipg = ipgLeavesDao.findIpgByKey(ipgKey).orElse(null);
        if (ipg == null) {
            errors.add("Карточка ipg не найдена: " + ipgKey);
            return fail(logCtx, loadSpan, previousHtml, persist, loadKey, ipgKey, previousIpgKey, dryRun, 0,
                    errors, problemRowIds);
        }
        if (ipg.ipgStRlSh() <= 0) {
            errors.add("У ipg=" + ipgKey + " не задан ipgStRlSh (схема структуры)");
            return fail(logCtx, loadSpan, previousHtml, persist, loadKey, ipgKey, previousIpgKey, dryRun, 0,
                    errors, problemRowIds);
        }

        String applySpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.APPLY, APPLY_START,
                "Применение пунктов к ИП " + ipgKey + (previousIpgKey != null
                        ? " (предыдущая ИП " + previousIpgKey + ")" : ""));

        String gateSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.GATE, GATE_START, "Gate: готовность ПТСФ");
        ImpIpgPointsGateResult gate = gateService.evaluate(loadKey);
        if (gate.openCount() > 0) {
            log.info(() -> "pointsApply gate soft-open load=" + loadKey
                    + " open=" + gate.openCount() + "/" + gate.sectionCount());
            logCtx.append(WARNING, ImpIpgLoadLogScope.GATE, GATE_SOFT_OPEN,
                    "ПТСФ не закрыт полностью: открыто " + gate.openCount() + " из " + gate.sectionCount()
                            + " (продолжаем — мягкий gate)",
                    Map.of("open", String.valueOf(gate.openCount()),
                            "sections", String.valueOf(gate.sectionCount())));
        } else {
            logCtx.append(SUCCESS, ImpIpgLoadLogScope.GATE, GATE_OK,
                    "ПТСФ закрыт: разделов " + gate.sectionCount());
        }
        logCtx.endSpan(gateSpan, INFO, ImpIpgLoadLogScope.GATE, GATE_END, "Gate завершён");

        String stiSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.STI, STI_INHERIT_START,
                "Наследование sti L←S");
        ImpIpgStiInheritResult sti = stiInheritService.evaluate(loadKey);
        logCtx.append(sti.holeCount() > 0 ? WARNING : SUCCESS, ImpIpgLoadLogScope.STI, STI_INHERIT_STATS,
                "листьев " + sti.leafCount() + ", готово " + sti.readyCount() + ", дыр " + sti.holeCount(),
                Map.of("leaf", String.valueOf(sti.leafCount()), "holes", String.valueOf(sti.holeCount())));
        logCtx.endSpan(stiSpan, INFO, ImpIpgLoadLogScope.STI, STI_INHERIT_END, "Наследование sti завершено");

        String shSpan = logCtx.beginSpan(INFO, ImpIpgLoadLogScope.SH, SH_RESOLVE_START,
                "Резолв схемы ipgpSh");
        ImpIpgShResolveResult sh = shResolveService.evaluate(loadKey, previousIpgKey);
        logCtx.append(sh.errorCount() > 0 ? WARNING : SUCCESS, ImpIpgLoadLogScope.SH, SH_RESOLVE_STATS,
                "резолвлено " + sh.resolvedCount() + " (из предыдущей " + sh.fromPrevCount()
                        + ", sh-default " + sh.default4Count() + ", свободный пул " + sh.freePoolCount()
                        + "), ошибок " + sh.errorCount(),
                Map.of("resolved", String.valueOf(sh.resolvedCount()),
                        "errors", String.valueOf(sh.errorCount())));
        logCtx.endSpan(shSpan, INFO, ImpIpgLoadLogScope.SH, SH_RESOLVE_END, "Резолв sh завершён");

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
            logCtx.endSpan(applySpan, ERROR, ImpIpgLoadLogScope.APPLY, APPLY_END, "Применение прервано");
            return fail(logCtx, loadSpan, previousHtml, persist, loadKey, ipgKey, previousIpgKey, dryRun, 0,
                    errors, problemRowIds);
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
                addError(errors, problemRowIds, errorsByCode, ERR_STI_HOLE, rowId,
                        ERR_STI_HOLE + " row=" + rowId + " reason=" + reason);
                continue;
            }
            ImpIpgShResolveLeaf shLeaf = shByRow.get(rowId);
            if (shLeaf == null || !shLeaf.ok()) {
                String reason = shLeaf == null ? "NO_SH_RESULT" : shLeaf.errorReason();
                addError(errors, problemRowIds, errorsByCode, ERR_SH, rowId,
                        ERR_SH + " row=" + rowId + " reason=" + reason);
                continue;
            }
            String code = shLeaf.cstAgPnCode();
            if (code == null || code.isBlank()) {
                addError(errors, problemRowIds, errorsByCode, ERR_CSTAGPN_MISSING, rowId,
                        ERR_CSTAGPN_MISSING + " row=" + rowId);
                continue;
            }
            CstAgPn cstAgPn = cstAgPnDao.findByCodeExact(code).orElse(null);
            if (cstAgPn == null || cstAgPn.cstapKey() == null) {
                addError(errors, problemRowIds, errorsByCode, ERR_CSTAGPN_MISSING, rowId,
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
            AggAxisResult agg = AggAxis.reconcileMln(
                    extractDecimal(ctx, "ttl"),
                    extractDecimal(ctx, "work"),
                    extractDecimal(ctx, "equip"),
                    extractDecimal(ctx, "others"));
            appendAggLog(logCtx, rowId, code, agg);
            if (agg.kind() == AggAxisKind.BLOCK) {
                addError(errors, problemRowIds, errorsByCode, ERR_AGG_BLOCK, rowId,
                        ERR_AGG_BLOCK + " code=" + code + " row=" + rowId
                                + " δ=" + agg.deltaBefore()
                                + " (Ttl≠Wrk+Equ+Oth; исправьте Excel или override)");
                continue;
            }
            drafts.add(new IpgPnBulkDraft(
                    rowId,
                    extractNnn(ctx),
                    cstAgPn.cstapKey(),
                    shKey,
                    agg.ttl(),
                    agg.wrk(),
                    agg.equ(),
                    agg.oth(),
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
            String html = closeApplyLog(logCtx, loadSpan, applySpan, previousHtml, false, loadKey,
                    true, leafCount, wouldApply, skippedDry, errors.size(), errorsByCode);
            return new ImpIpgPointsApplyResult(
                    loadKey, ipgKey, previousIpgKey, true, leafCount, wouldApply,
                    skippedDry, ready, errors, problemRowIds, List.of(), html);
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
                    addError(errors, problemRowIds, errorsByCode, ERR_INSERT_FAIL, draft.stagingRowId(),
                            ERR_INSERT_FAIL + " row=" + draft.stagingRowId() + " " + message);
                }
            } catch (DaoException ex) {
                addError(errors, problemRowIds, errorsByCode, ERR_INSERT_FAIL, draft.stagingRowId(),
                        ERR_INSERT_FAIL + " row=" + draft.stagingRowId() + " " + ex.getMessage());
            }
        }

        boolean ready = errors.isEmpty();
        final int applied = created.size();
        final int skipped = skippedAlready;
        log.info(() -> "pointsApply committed load=" + loadKey + " ipg=" + ipgKey
                + " applied=" + applied + " skippedAlready=" + skipped
                + " errors=" + errors.size() + " ready=" + ready);
        String html = closeApplyLog(logCtx, loadSpan, applySpan, previousHtml, true, loadKey,
                false, leafCount, applied, skipped, errors.size(), errorsByCode);
        return new ImpIpgPointsApplyResult(
                loadKey, ipgKey, previousIpgKey, false, leafCount, applied,
                skippedAlready, ready, errors, problemRowIds, created, html);
    }

    /**
     * Закрывает блоки APPLY / LOAD: свёртка ошибок по коду, пропуски «уже есть», итог; возвращает
     * накопительный HTML (при {@code persist} — записывает в {@code iilResults}).
     */
    private String closeApplyLog(
            ImpIpgLoadLogContext logCtx,
            String loadSpan,
            String applySpan,
            String previousHtml,
            boolean persist,
            int loadKey,
            boolean dryRun,
            int leafCount,
            int appliedOrWould,
            int skippedAlready,
            int errorCount,
            Map<String, List<String>> errorsByCode) {
        for (Map.Entry<String, List<String>> group : errorsByCode.entrySet()) {
            List<String> items = group.getValue();
            StringBuilder sb = new StringBuilder();
            sb.append("<b>").append(ImpIpgLoadLogContext.esc(group.getKey())).append("</b>: ")
                    .append(items.size()).append(" стр.");
            int shown = Math.min(items.size(), ImpIpgLoadLogSupport.MAX_ERROR_SAMPLES);
            sb.append(" — ");
            for (int i = 0; i < shown; i++) {
                if (i > 0) {
                    sb.append("; ");
                }
                sb.append(ImpIpgLoadLogContext.esc(items.get(i)));
            }
            if (items.size() > shown) {
                sb.append("; … ещё ").append(items.size() - shown);
            }
            logCtx.append(ERROR, ImpIpgLoadLogScope.APPLY, APPLY_ROW_ERR, sb.toString(),
                    Map.of("reason", group.getKey(), "count", String.valueOf(items.size())));
        }
        if (skippedAlready > 0) {
            logCtx.append(INFO, ImpIpgLoadLogScope.APPLY, APPLY_SKIP_ALREADY,
                    SKIP_ALREADY + ": уже есть в домене " + skippedAlready + " пункт(ов) — пропущено",
                    Map.of("count", String.valueOf(skippedAlready)));
        }
        logCtx.append(SUMMARY, ImpIpgLoadLogScope.SUMMARY, APPLY_STATS,
                "листьев " + leafCount + ", " + (dryRun ? "будет применено " : "применено ") + appliedOrWould
                        + ", пропущено (уже есть) " + skippedAlready + ", ошибок " + errorCount,
                Map.of("leaf", String.valueOf(leafCount), "applied", String.valueOf(appliedOrWould),
                        "skipped", String.valueOf(skippedAlready), "errors", String.valueOf(errorCount)));
        logCtx.endSpan(applySpan, errorCount > 0 ? WARNING : SUCCESS, ImpIpgLoadLogScope.APPLY, APPLY_END,
                "Применение завершено");
        logCtx.endSpan(loadSpan, errorCount > 0 ? WARNING : SUCCESS, ImpIpgLoadLogScope.LOAD, IPG_LOAD_END,
                "Загрузка пунктов завершена" + (dryRun ? " (dry-run, лог не сохраняется в сессии)" : ""));
        return ImpIpgLoadLogSupport.finishAndPersist(
                logCtx, previousHtml, persist, loadDao::updateLoadResults, loadKey, log);
    }

    private static String uniqueKey(int cstAgPnKey, int sh) {
        return cstAgPnKey + "|" + sh;
    }

    private static void addError(
            List<String> errors,
            List<Integer> problemRowIds,
            Map<String, List<String>> errorsByCode,
            String code,
            int rowId,
            String message) {
        errors.add(message);
        problemRowIds.add(rowId);
        errorsByCode.computeIfAbsent(code, k -> new ArrayList<>()).add(message);
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

    /**
     * Пишет событие R-MONEY-AGG в spine лога (кроме чистого OK без сумм).
     */
    private static void appendAggLog(
            ImpIpgLoadLogContext logCtx, int rowId, String cstCode, AggAxisResult agg) {
        if (agg.kind() == AggAxisKind.OK) {
            return;
        }
        var level = switch (agg.kind()) {
            case QUANTUM_FIX -> INFO;
            case AUTHOR_FIX, STRUCT -> WARNING;
            case BLOCK -> ERROR;
            default -> INFO;
        };
        String code = switch (agg.kind()) {
            case QUANTUM_FIX -> AGG_QUANTUM_FIX;
            case AUTHOR_FIX -> AGG_AUTHOR_FIX;
            case STRUCT -> AGG_STRUCT;
            case BLOCK -> AGG_BLOCK;
            default -> AGG_OK;
        };
        String msg = code + " row=" + rowId + " cst=" + ImpIpgLoadLogContext.esc(cstCode)
                + " δ=" + agg.deltaBefore()
                + " → ttl=" + agg.ttl() + " wrk=" + agg.wrk()
                + " equ=" + agg.equ() + " oth=" + agg.oth();
        logCtx.append(level, ImpIpgLoadLogScope.APPLY, code, msg,
                Map.of("row", String.valueOf(rowId), "kind", agg.kind().name(),
                        "delta", String.valueOf(agg.deltaBefore())));
    }

    /**
     * Жёсткий отказ прохода: IPG_LOAD_ERROR в логе, накопительный HTML в результате.
     */
    private ImpIpgPointsApplyResult fail(
            ImpIpgLoadLogContext logCtx,
            String loadSpan,
            String previousHtml,
            boolean persist,
            int loadKey,
            int ipgKey,
            Integer previousIpgKey,
            boolean dryRun,
            int leafCount,
            List<String> errors,
            List<Integer> problemRowIds) {
        for (String error : errors) {
            logCtx.append(ERROR, ImpIpgLoadLogScope.LOAD, IPG_LOAD_ERROR, ImpIpgLoadLogContext.esc(error));
        }
        logCtx.endSpan(loadSpan, ERROR, ImpIpgLoadLogScope.LOAD, IPG_LOAD_ERROR,
                "Загрузка пунктов прервана");
        String html = ImpIpgLoadLogSupport.finishAndPersist(
                logCtx, previousHtml, persist && !dryRun, loadDao::updateLoadResults, loadKey, log);
        return new ImpIpgPointsApplyResult(
                loadKey, ipgKey, previousIpgKey, dryRun, leafCount, 0, 0,
                false, errors, problemRowIds, List.of(), html);
    }
}
