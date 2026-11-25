package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgRow;
import com.femsq.database.model.ImpIpgStiInheritLeaf;
import com.femsq.database.model.ImpIpgStiInheritResult;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * Резолв sti листа из {@code iiParent} → раздел S.{@code iiStiKey} (§3.2.2).
 *
 * <p>Значение {@code iiStiKey} на самой строке L не используется и не записывается —
 * источник истины для apply: sti закрытого родителя-раздела.
 */
public class DefaultImpIpgStiInheritService implements ImpIpgStiInheritService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgStiInheritService.class.getName());

    static final String HOLE_NO_PARENT = "NO_PARENT";
    static final String HOLE_PARENT_MISSING = "PARENT_MISSING";
    static final String HOLE_PARENT_NOT_SECTION = "PARENT_NOT_SECTION";
    static final String HOLE_PARENT_STI_MISSING = "PARENT_STI_MISSING";

    private final ImpIpgLoadDao loadDao;

    /**
     * @param loadDao сессии и строки staging
     */
    public DefaultImpIpgStiInheritService(ImpIpgLoadDao loadDao) {
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
    }

    @Override
    public ImpIpgStiInheritResult evaluate(int loadKey) {
        log.info(() -> "stiInherit evaluate load=" + loadKey);
        List<String> errors = new ArrayList<>();

        ImpIpgLoad load = loadDao.findLoadByKey(loadKey).orElse(null);
        if (load == null) {
            errors.add("Сессия impIpgLoad не найдена: " + loadKey);
            return emptyFail(loadKey, 0, errors);
        }

        int ipgKey = load.iilIpg();
        List<ImpIpgRow> allRows = loadDao.findRowsByLoad(loadKey);
        Map<Integer, ImpIpgRow> byKey = new HashMap<>();
        for (ImpIpgRow row : allRows) {
            byKey.put(row.iiKey(), row);
        }

        List<ImpIpgStiInheritLeaf> holes = new ArrayList<>();
        List<ImpIpgStiInheritLeaf> readyLeaves = new ArrayList<>();

        for (ImpIpgRow leaf : allRows) {
            if (!isLeaf(leaf)) {
                continue;
            }
            ImpIpgStiInheritLeaf resolved = resolveLeaf(leaf, byKey);
            if (resolved.ready()) {
                readyLeaves.add(resolved);
            } else {
                holes.add(resolved);
            }
        }

        int leafCount = readyLeaves.size() + holes.size();
        if (leafCount == 0) {
            errors.add("В сессии нет листьев (iiRowKind=L); выполните разбор Excel");
        }
        if (!holes.isEmpty()) {
            errors.add("Листья без sti родителя: hole=" + holes.size() + " из " + leafCount
                    + " (дыра = ERROR при apply)");
        }

        boolean ready = errors.isEmpty();
        log.info(() -> "stiInherit load=" + loadKey + " ipg=" + ipgKey
                + " leaves=" + leafCount + " ready=" + readyLeaves.size()
                + " holes=" + holes.size() + " ok=" + ready);
        return new ImpIpgStiInheritResult(
                loadKey,
                ipgKey,
                leafCount,
                readyLeaves.size(),
                holes.size(),
                ready,
                errors,
                holes,
                readyLeaves);
    }

    @Override
    public ImpIpgStiInheritResult assertReady(int loadKey) {
        ImpIpgStiInheritResult result = evaluate(loadKey);
        if (!result.ready()) {
            String message = result.errors().isEmpty()
                    ? "Наследование sti: сессия " + loadKey + " не готова"
                    : "Наследование sti: " + String.join("; ", result.errors());
            throw new DaoException(message);
        }
        return result;
    }

    private static ImpIpgStiInheritLeaf resolveLeaf(ImpIpgRow leaf, Map<Integer, ImpIpgRow> byKey) {
        Integer parentKey = leaf.iiParent();
        if (parentKey == null) {
            return hole(leaf, HOLE_NO_PARENT);
        }
        ImpIpgRow parent = byKey.get(parentKey);
        if (parent == null) {
            return hole(leaf, HOLE_PARENT_MISSING);
        }
        if (!parent.isStructure()) {
            return hole(leaf, HOLE_PARENT_NOT_SECTION);
        }
        Integer sti = parent.iiStiKey();
        if (sti == null) {
            return hole(leaf, HOLE_PARENT_STI_MISSING);
        }
        return new ImpIpgStiInheritLeaf(
                leaf.iiKey(),
                leaf.iiRowNo(),
                leaf.iiText(),
                parentKey,
                sti,
                null);
    }

    private static ImpIpgStiInheritLeaf hole(ImpIpgRow leaf, String reason) {
        return new ImpIpgStiInheritLeaf(
                leaf.iiKey(),
                leaf.iiRowNo(),
                leaf.iiText(),
                leaf.iiParent(),
                null,
                reason);
    }

    private static boolean isLeaf(ImpIpgRow row) {
        return "L".equalsIgnoreCase(row.iiRowKind());
    }

    private static ImpIpgStiInheritResult emptyFail(int loadKey, int ipgKey, List<String> errors) {
        return new ImpIpgStiInheritResult(
                loadKey, ipgKey, 0, 0, 0, false, errors, List.of(), List.of());
    }
}
