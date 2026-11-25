package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgShResolveLeaf;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgShResolveSource;
import com.femsq.database.model.IpgPn;
import com.femsq.database.model.IpgSh;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Алгоритм {@code ipgpSh} (§3.2.3 / notes O1 §5.2).
 *
 * <ul>
 *   <li>код 1 раз в файле: ровно 1 схема в prev → её; иначе → 4;</li>
 *   <li>код N&gt;1 раз: N различных схем (сначала prev, затем свободные {@code ipgSh}); иначе ERROR;</li>
 *   <li>unique в пакете: (cstAgPn, sh) не дублируется.</li>
 * </ul>
 */
public class DefaultImpIpgShResolveService implements ImpIpgShResolveService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgShResolveService.class.getName());

    /** Ключ «Не определена». */
    public static final int DEFAULT_UNDEFINED_SH = 4;

    static final String ERR_MISSING_CODE = "MISSING_CSTAGPN";
    static final String ERR_NO_SCHEMES = "NO_FREE_SCHEMES";
    static final String ERR_UNIQUE = "UNIQUE_CSTAGPN_SH";

    private static final Pattern CST_AG_PN_FIELD =
            Pattern.compile("\"cstAgPn\"\\s*:\\s*\"([^\"]*)\"");

    private final ImpIpgLoadDao loadDao;
    private final IpgLeavesDao ipgLeavesDao;

    /**
     * @param loadDao      сессии/строки staging
     * @param ipgLeavesDao пункты prev-IP и справочник {@code ipgSh}
     */
    public DefaultImpIpgShResolveService(ImpIpgLoadDao loadDao, IpgLeavesDao ipgLeavesDao) {
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
        this.ipgLeavesDao = Objects.requireNonNull(ipgLeavesDao, "ipgLeavesDao");
    }

    @Override
    public ImpIpgShResolveResult evaluate(int loadKey, Integer previousIpgKey) {
        log.info(() -> "shResolve evaluate load=" + loadKey + " prevIpg=" + previousIpgKey);
        List<String> errors = new ArrayList<>();

        ImpIpgLoad load = loadDao.findLoadByKey(loadKey).orElse(null);
        if (load == null) {
            errors.add("Сессия impIpgLoad не найдена: " + loadKey);
            return emptyFail(loadKey, 0, previousIpgKey, errors);
        }
        int ipgKey = load.iilIpg();

        List<ImpIpgRow> leaves = loadDao.findRowsByLoad(loadKey).stream()
                .filter(row -> "L".equalsIgnoreCase(row.iiRowKind()))
                .sorted(Comparator.comparingInt(ImpIpgRow::iiRowNo).thenComparingInt(ImpIpgRow::iiKey))
                .collect(Collectors.toList());

        if (leaves.isEmpty()) {
            errors.add("В сессии нет листьев (iiRowKind=L); выполните разбор Excel");
            return new ImpIpgShResolveResult(
                    loadKey, ipgKey, previousIpgKey, 0, 0, 0, 0, 0, 0,
                    false, errors, List.of(), List.of());
        }

        Map<String, List<Integer>> prevSchemesByCode = buildPrevSchemes(previousIpgKey);
        List<Integer> allShKeys = ipgLeavesDao.findAllSh().stream()
                .map(IpgSh::ipgsKey)
                .sorted()
                .collect(Collectors.toList());
        if (!allShKeys.contains(DEFAULT_UNDEFINED_SH)) {
            errors.add("В справочнике ipgSh нет ключа " + DEFAULT_UNDEFINED_SH + " («Не определена»)");
        }

        Map<String, List<ImpIpgRow>> byCode = new LinkedHashMap<>();
        List<ImpIpgShResolveLeaf> missingCode = new ArrayList<>();
        for (ImpIpgRow leaf : leaves) {
            String code = extractCstAgPn(leaf.iiCtx());
            if (code == null || code.isBlank()) {
                missingCode.add(problem(leaf, null, ERR_MISSING_CODE));
                continue;
            }
            byCode.computeIfAbsent(code, ignored -> new ArrayList<>()).add(leaf);
        }

        List<ImpIpgShResolveLeaf> resolved = new ArrayList<>();
        List<ImpIpgShResolveLeaf> problems = new ArrayList<>(missingCode);

        for (Map.Entry<String, List<ImpIpgRow>> entry : byCode.entrySet()) {
            String code = entry.getKey();
            List<ImpIpgRow> group = entry.getValue();
            List<Integer> prev = prevSchemesByCode.getOrDefault(code, List.of());
            assignGroup(code, group, prev, allShKeys, resolved, problems);
        }

        // unique в пакете (cstAgPn, sh)
        Set<String> seen = new HashSet<>();
        List<ImpIpgShResolveLeaf> afterUnique = new ArrayList<>();
        for (ImpIpgShResolveLeaf leaf : resolved) {
            String key = leaf.cstAgPnCode() + "|" + leaf.resolvedSh();
            if (!seen.add(key)) {
                problems.add(new ImpIpgShResolveLeaf(
                        leaf.rowId(),
                        leaf.rowNo(),
                        leaf.text(),
                        leaf.cstAgPnCode(),
                        null,
                        null,
                        ERR_UNIQUE));
            } else {
                afterUnique.add(leaf);
            }
        }
        resolved = afterUnique;

        if (!problems.isEmpty()) {
            errors.add("Резолв ipgpSh: ошибок=" + problems.size() + " из " + leaves.size());
        }

        int fromPrev = (int) resolved.stream()
                .filter(l -> l.source() == ImpIpgShResolveSource.FROM_PREV).count();
        int def4 = (int) resolved.stream()
                .filter(l -> l.source() == ImpIpgShResolveSource.DEFAULT_4).count();
        int free = (int) resolved.stream()
                .filter(l -> l.source() == ImpIpgShResolveSource.FREE_POOL).count();

        boolean ready = errors.isEmpty() && problems.isEmpty();
        final int okCount = resolved.size();
        final int errCount = problems.size();
        log.info(() -> "shResolve load=" + loadKey + " ipg=" + ipgKey
                + " leaves=" + leaves.size() + " ok=" + okCount
                + " err=" + errCount + " fromPrev=" + fromPrev
                + " def4=" + def4 + " free=" + free + " ready=" + ready);

        return new ImpIpgShResolveResult(
                loadKey,
                ipgKey,
                previousIpgKey,
                leaves.size(),
                resolved.size(),
                problems.size(),
                fromPrev,
                def4,
                free,
                ready,
                errors,
                problems,
                resolved);
    }

    @Override
    public ImpIpgShResolveResult assertReady(int loadKey, Integer previousIpgKey) {
        ImpIpgShResolveResult result = evaluate(loadKey, previousIpgKey);
        if (!result.ready()) {
            String message = result.errors().isEmpty()
                    ? "Резолв ipgpSh: сессия " + loadKey + " не готова"
                    : "Резолв ipgpSh: " + String.join("; ", result.errors());
            throw new DaoException(message);
        }
        return result;
    }

    private void assignGroup(
            String code,
            List<ImpIpgRow> group,
            List<Integer> prevDistinct,
            List<Integer> allShKeys,
            List<ImpIpgShResolveLeaf> resolved,
            List<ImpIpgShResolveLeaf> problems) {
        int n = group.size();
        if (n == 1) {
            ImpIpgRow leaf = group.get(0);
            if (prevDistinct.size() == 1) {
                resolved.add(ok(leaf, code, prevDistinct.get(0), ImpIpgShResolveSource.FROM_PREV));
            } else {
                resolved.add(ok(leaf, code, DEFAULT_UNDEFINED_SH, ImpIpgShResolveSource.DEFAULT_4));
            }
            return;
        }

        // N>1: нужны N различных схем
        List<Integer> assigned = new ArrayList<>();
        List<ImpIpgShResolveSource> sources = new ArrayList<>();
        for (Integer sh : prevDistinct) {
            if (assigned.size() >= n) {
                break;
            }
            if (!assigned.contains(sh)) {
                assigned.add(sh);
                sources.add(ImpIpgShResolveSource.FROM_PREV);
            }
        }
        for (Integer sh : allShKeys) {
            if (assigned.size() >= n) {
                break;
            }
            if (!assigned.contains(sh)) {
                assigned.add(sh);
                sources.add(ImpIpgShResolveSource.FREE_POOL);
            }
        }

        if (assigned.size() < n) {
            for (ImpIpgRow leaf : group) {
                problems.add(problem(leaf, code, ERR_NO_SCHEMES));
            }
            return;
        }

        for (int i = 0; i < n; i++) {
            resolved.add(ok(group.get(i), code, assigned.get(i), sources.get(i)));
        }
    }

    private Map<String, List<Integer>> buildPrevSchemes(Integer previousIpgKey) {
        if (previousIpgKey == null || previousIpgKey <= 0) {
            return Map.of();
        }
        List<IpgPn> pns = ipgLeavesDao.findPnsByIpg(previousIpgKey);
        Map<String, LinkedHashSet<Integer>> acc = new HashMap<>();
        List<IpgPn> ordered = pns.stream()
                .sorted(Comparator.comparingInt(IpgPn::ipgpKey))
                .collect(Collectors.toList());
        for (IpgPn pn : ordered) {
            String code = pn.cstAgPnCode();
            if (code == null || code.isBlank()) {
                continue;
            }
            acc.computeIfAbsent(code, ignored -> new LinkedHashSet<>()).add(pn.ipgpSh());
        }
        Map<String, List<Integer>> result = new HashMap<>();
        for (Map.Entry<String, LinkedHashSet<Integer>> e : acc.entrySet()) {
            result.put(e.getKey(), List.copyOf(e.getValue()));
        }
        return result;
    }

    static String extractCstAgPn(String ctx) {
        if (ctx == null || ctx.isBlank()) {
            return null;
        }
        Matcher matcher = CST_AG_PN_FIELD.matcher(ctx);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        return null;
    }

    private static ImpIpgShResolveLeaf ok(
            ImpIpgRow leaf, String code, int sh, ImpIpgShResolveSource source) {
        return new ImpIpgShResolveLeaf(
                leaf.iiKey(), leaf.iiRowNo(), leaf.iiText(), code, sh, source, null);
    }

    private static ImpIpgShResolveLeaf problem(ImpIpgRow leaf, String code, String reason) {
        return new ImpIpgShResolveLeaf(
                leaf.iiKey(), leaf.iiRowNo(), leaf.iiText(), code, null, null, reason);
    }

    private static ImpIpgShResolveResult emptyFail(
            int loadKey, int ipgKey, Integer previousIpgKey, List<String> errors) {
        return new ImpIpgShResolveResult(
                loadKey, ipgKey, previousIpgKey, 0, 0, 0, 0, 0, 0,
                false, errors, List.of(), List.of());
    }
}
