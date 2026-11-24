package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.StIpgStructureDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgReconcileResult;
import com.femsq.database.model.ImpIpgReconcileRow;
import com.femsq.database.model.ImpIpgReconcileStatus;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.StIpgNm;
import com.femsq.database.model.StIpgTreeNode;
import com.femsq.database.model.StNetworkFull;
import com.femsq.database.util.StructureNameNormalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Реализация сверки ПТСФ: имя∪alias + OR по путям DAG.
 */
public class DefaultImpIpgReconcileService implements ImpIpgReconcileService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgReconcileService.class.getName());
    private static final Pattern PATH_ARRAY = Pattern.compile("\"path\"\\s*:\\s*\\[(.*?)]", Pattern.DOTALL);
    private static final Pattern PATH_ITEM = Pattern.compile("\"((?:\\\\.|[^\"\\\\])*)\"");
    private static final Pattern TITLE_FIELD = Pattern.compile("\"title\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");

    private final ImpIpgLoadDao loadDao;
    private final StIpgStructureDao structureDao;

    public DefaultImpIpgReconcileService(ImpIpgLoadDao loadDao, StIpgStructureDao structureDao) {
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
        this.structureDao = Objects.requireNonNull(structureDao, "structureDao");
    }

    @Override
    public ImpIpgReconcileResult reconcile(int loadKey, int stNetKey, boolean persistMatches) {
        if (loadDao.findLoadByKey(loadKey).isEmpty()) {
            throw new DaoException("impIpgLoad не найден: " + loadKey);
        }
        StNetworkFull network = structureDao.findNetworkByKey(stNetKey)
                .orElseThrow(() -> new DaoException("stNet не найден: " + stNetKey));

        List<ImpIpgRow> sections = loadDao.findStructureRowsByLoad(loadKey);
        List<StIpgTreeNode> tree = structureDao.findTree(stNetKey, network.stnRoot());
        Index index = buildIndex(tree);

        log.info(() -> "reconcile load=" + loadKey + " stNet=" + stNetKey
                + " sections=" + sections.size() + " nodes=" + index.nodeKeys.size());

        List<ImpIpgReconcileRow> rows = new ArrayList<>();
        int matched = 0;
        int open = 0;
        for (ImpIpgRow section : sections) {
            ImpIpgReconcileRow row = matchSection(section, index);
            if (persistMatches
                    && row.stiKey() != null
                    && (row.status() == ImpIpgReconcileStatus.MATCHED
                    || row.status() == ImpIpgReconcileStatus.NEEDS_ALIAS)
                    && !Objects.equals(section.iiStiKey(), row.stiKey())) {
                loadDao.updateRow(
                        section.iiKey(),
                        section.iiRowNo(),
                        section.iiRowKind(),
                        section.iiText(),
                        section.iiParent(),
                        row.stiKey(),
                        section.iiCtx());
            }
            rows.add(row);
            if (row.closed()) {
                matched++;
            } else {
                open++;
            }
        }
        return new ImpIpgReconcileResult(loadKey, stNetKey, matched, open, List.copyOf(rows));
    }

    private ImpIpgReconcileRow matchSection(ImpIpgRow section, Index index) {
        String rawText = section.iiText() == null ? "" : section.iiText();
        String title = extractTitle(section.iiCtx(), rawText);
        String rawTitle = title.isEmpty() ? StructureNameNormalizer.stripSectionNumber(rawText) : title;
        String normTitle = StructureNameNormalizer.normalize(rawTitle.isEmpty() ? rawText : rawTitle);
        List<String> excelPath = extractPath(section.iiCtx());
        List<String> normExcelPath = excelPath.stream().map(StructureNameNormalizer::normalize).toList();

        if (section.iiStiKey() != null) {
            boolean inPool = nameInPool(section.iiStiKey(), rawText, rawTitle, normTitle, index);
            boolean pathOk = pathMatches(section.iiStiKey(), normExcelPath, index);
            // MANUAL: оператор уже выбрал stiKey (часто после PATH_MISMATCH/HOMONYM).
            // Закрываем по имени в пуле; pathMatched остаётся диагностикой
            // (Excel path после вложенных S с iiParent=null может быть испорчен).
            boolean manualClosed = inPool;
            return new ImpIpgReconcileRow(
                    section.iiKey(),
                    section.iiRowNo(),
                    rawText,
                    section.iiStiKey(),
                    ImpIpgReconcileStatus.MANUAL,
                    List.of(section.iiStiKey()),
                    pathOk,
                    inPool,
                    manualClosed);
        }

        Set<Integer> nameHits = new LinkedHashSet<>();
        boolean anyRawHit = false;
        for (Map.Entry<Integer, Set<String>> entry : index.normNamesBySti.entrySet()) {
            if (entry.getValue().contains(normTitle)) {
                nameHits.add(entry.getKey());
                anyRawHit = true;
            }
        }
        // точное сырое совпадение без нормализации (опечатки в пуле)
        for (Map.Entry<Integer, Set<String>> entry : index.rawNamesBySti.entrySet()) {
            if (entry.getValue().contains(rawText) || entry.getValue().contains(rawTitle)) {
                nameHits.add(entry.getKey());
                anyRawHit = true;
            }
        }

        if (nameHits.isEmpty()) {
            return new ImpIpgReconcileRow(
                    section.iiKey(), section.iiRowNo(), rawText, null,
                    ImpIpgReconcileStatus.UNMATCHED, List.of(), false, false, false);
        }

        Set<Integer> pathHits = new LinkedHashSet<>();
        for (Integer sti : nameHits) {
            if (pathMatches(sti, normExcelPath, index)) {
                pathHits.add(sti);
            }
        }

        if (pathHits.size() == 1) {
            int sti = pathHits.iterator().next();
            boolean inPool = nameInPool(sti, rawText, rawTitle, normTitle, index);
            if (inPool) {
                return new ImpIpgReconcileRow(
                        section.iiKey(), section.iiRowNo(), rawText, sti,
                        ImpIpgReconcileStatus.MATCHED, List.of(sti), true, true, true);
            }
            return new ImpIpgReconcileRow(
                    section.iiKey(), section.iiRowNo(), rawText, sti,
                    ImpIpgReconcileStatus.NEEDS_ALIAS, List.of(sti), true, false, false);
        }

        if (pathHits.isEmpty()) {
            return new ImpIpgReconcileRow(
                    section.iiKey(), section.iiRowNo(), rawText, null,
                    ImpIpgReconcileStatus.PATH_MISMATCH,
                    List.copyOf(nameHits), false, anyRawHit, false);
        }

        return new ImpIpgReconcileRow(
                section.iiKey(), section.iiRowNo(), rawText, null,
                ImpIpgReconcileStatus.HOMONYM,
                List.copyOf(pathHits.isEmpty() ? nameHits : pathHits),
                false, anyRawHit, false);
    }

    /**
     * Имя считается в пуле, если совпал сырой текст/title или нормализованный title.
     */
    private static boolean nameInPool(
            int stiKey,
            String rawText,
            String rawTitle,
            String normTitle,
            Index index) {
        Set<String> raws = index.rawNamesBySti.getOrDefault(stiKey, Set.of());
        if (raws.contains(rawText) || raws.contains(rawTitle)) {
            return true;
        }
        if (normTitle == null || normTitle.isEmpty()) {
            return false;
        }
        return index.normNamesBySti.getOrDefault(stiKey, Set.of()).contains(normTitle);
    }

    private static boolean pathMatches(int stiKey, List<String> normExcelPath, Index index) {
        if (normExcelPath.isEmpty()) {
            // без пути из Excel нельзя закрыть омоним; для единственного имени — не OK по контракту
            return false;
        }
        List<List<String>> paths = index.normPathsBySti.getOrDefault(stiKey, List.of());
        for (List<String> domainPath : paths) {
            if (pathsEqualOrSuffix(domainPath, normExcelPath)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Совпадение путей Excel ↔ дерево:
     * <ul>
     *   <li>полное равенство;</li>
     *   <li>один путь — непрерывный суффикс другого (лишние предки корня / «План КС»);</li>
     *   <li>или более короткий путь — упорядоченная подпоследовательность более длинного
     *       (Excel часто пропускает служебные уровни вроде «Структура целей / видов»).</li>
     * </ul>
     */
    private static boolean pathsEqualOrSuffix(List<String> a, List<String> b) {
        if (a.equals(b)) {
            return true;
        }
        if (a.isEmpty() || b.isEmpty()) {
            return false;
        }
        if (a.size() >= b.size()) {
            if (a.subList(a.size() - b.size(), a.size()).equals(b)) {
                return true;
            }
            return isOrderedSubsequence(b, a);
        }
        if (b.subList(b.size() - a.size(), b.size()).equals(a)) {
            return true;
        }
        return isOrderedSubsequence(a, b);
    }

    /**
     * Все элементы needle встречаются в haystack в том же порядке (не обязательно подряд).
     */
    private static boolean isOrderedSubsequence(List<String> needle, List<String> haystack) {
        int from = 0;
        for (String part : needle) {
            int idx = -1;
            for (int i = from; i < haystack.size(); i++) {
                if (Objects.equals(part, haystack.get(i))) {
                    idx = i;
                    break;
                }
            }
            if (idx < 0) {
                return false;
            }
            from = idx + 1;
        }
        return true;
    }

    private Index buildIndex(List<StIpgTreeNode> tree) {
        Map<Integer, Integer> parentByChild = new HashMap<>();
        Map<Integer, String> primaryName = new HashMap<>();
        Set<Integer> nodeKeys = new HashSet<>();
        Integer root = null;
        for (StIpgTreeNode node : tree) {
            nodeKeys.add(node.childKey());
            if (node.parentKey() != null) {
                parentByChild.put(node.childKey(), node.parentKey());
            } else if (root == null) {
                root = node.childKey();
            }
            if (node.name() != null && !node.name().isBlank()) {
                primaryName.put(node.childKey(), node.name());
            }
        }

        Map<Integer, Set<String>> rawNames = new HashMap<>();
        Map<Integer, Set<String>> normNames = new HashMap<>();
        for (Integer sti : nodeKeys) {
            List<StIpgNm> names = structureDao.findNodeNames(sti);
            Set<String> raw = new HashSet<>();
            Set<String> norm = new HashSet<>();
            for (StIpgNm nm : names) {
                if (nm.stinNm() == null || nm.stinNm().isBlank()) {
                    continue;
                }
                raw.add(nm.stinNm());
                norm.add(StructureNameNormalizer.normalize(nm.stinNm()));
            }
            String primary = primaryName.get(sti);
            if (primary != null) {
                raw.add(primary);
                norm.add(StructureNameNormalizer.normalize(primary));
            }
            rawNames.put(sti, raw);
            normNames.put(sti, norm);
        }

        Map<Integer, List<List<String>>> paths = new HashMap<>();
        for (Integer sti : nodeKeys) {
            paths.put(sti, enumerateNormPaths(sti, parentByChild, primaryName, normNames));
        }
        return new Index(nodeKeys, rawNames, normNames, paths);
    }

    private static List<List<String>> enumerateNormPaths(
            int stiKey,
            Map<Integer, Integer> parentByChild,
            Map<Integer, String> primaryName,
            Map<Integer, Set<String>> normNames) {
        List<Integer> chain = new ArrayList<>();
        Integer current = stiKey;
        Set<Integer> guard = new HashSet<>();
        while (current != null && guard.add(current)) {
            chain.add(0, current);
            current = parentByChild.get(current);
        }
        // один путь по primary; если у узла несколько имён — OR на последнем сегменте
        Set<String> leafNames = normNames.getOrDefault(stiKey, Set.of());
        if (leafNames.isEmpty()) {
            String primary = primaryName.get(stiKey);
            if (primary != null) {
                leafNames = Set.of(StructureNameNormalizer.normalize(primary));
            }
        }
        List<List<String>> result = new ArrayList<>();
        for (String leafNorm : leafNames) {
            List<String> path = new ArrayList<>();
            for (int i = 0; i < chain.size() - 1; i++) {
                int key = chain.get(i);
                String name = primaryName.get(key);
                path.add(StructureNameNormalizer.normalize(name == null ? "" : name));
            }
            path.add(leafNorm);
            result.add(List.copyOf(path));
        }
        if (result.isEmpty()) {
            List<String> path = new ArrayList<>();
            for (Integer key : chain) {
                String name = primaryName.get(key);
                path.add(StructureNameNormalizer.normalize(name == null ? "" : name));
            }
            result.add(List.copyOf(path));
        }
        return result;
    }

    private static String extractTitle(String ctx, String fallbackText) {
        if (ctx != null) {
            Matcher matcher = TITLE_FIELD.matcher(ctx);
            if (matcher.find()) {
                return unescapeJson(matcher.group(1));
            }
        }
        return StructureNameNormalizer.stripSectionNumber(fallbackText);
    }

    private static List<String> extractPath(String ctx) {
        if (ctx == null || ctx.isBlank()) {
            return List.of();
        }
        Matcher array = PATH_ARRAY.matcher(ctx);
        if (!array.find()) {
            return List.of();
        }
        List<String> items = new ArrayList<>();
        Matcher item = PATH_ITEM.matcher(array.group(1));
        while (item.find()) {
            items.add(unescapeJson(item.group(1)));
        }
        return items;
    }

    private static String unescapeJson(String value) {
        return value
                .replace("\\\"", "\"")
                .replace("\\\\", "\\")
                .replace("\\n", "\n")
                .replace("\\t", "\t");
    }

    private record Index(
            Set<Integer> nodeKeys,
            Map<Integer, Set<String>> rawNamesBySti,
            Map<Integer, Set<String>> normNamesBySti,
            Map<Integer, List<List<String>>> normPathsBySti) {
    }
}
