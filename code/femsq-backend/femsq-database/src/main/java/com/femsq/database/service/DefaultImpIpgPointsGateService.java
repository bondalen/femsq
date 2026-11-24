package com.femsq.database.service;

import com.femsq.database.dao.ImpIpgLoadDao;
import com.femsq.database.dao.IpgLeavesDao;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgReconcileResult;
import com.femsq.database.model.ImpIpgReconcileRow;
import com.femsq.database.model.IpgFull;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;
import java.util.stream.Collectors;

/**
 * Gate §3.2.1: {@code ipg.ipgStRlSh} задан и сверка ПТСФ даёт {@code open=0}.
 */
public class DefaultImpIpgPointsGateService implements ImpIpgPointsGateService {

    private static final Logger log = Logger.getLogger(DefaultImpIpgPointsGateService.class.getName());

    private final ImpIpgLoadDao loadDao;
    private final IpgLeavesDao ipgLeavesDao;
    private final ImpIpgReconcileService reconcileService;

    /**
     * @param loadDao           сессии/строки staging
     * @param ipgLeavesDao      карточка ipg ({@code ipgStRlSh})
     * @param reconcileService  сверка ПТСФ без записи
     */
    public DefaultImpIpgPointsGateService(
            ImpIpgLoadDao loadDao,
            IpgLeavesDao ipgLeavesDao,
            ImpIpgReconcileService reconcileService) {
        this.loadDao = Objects.requireNonNull(loadDao, "loadDao");
        this.ipgLeavesDao = Objects.requireNonNull(ipgLeavesDao, "ipgLeavesDao");
        this.reconcileService = Objects.requireNonNull(reconcileService, "reconcileService");
    }

    @Override
    public ImpIpgPointsGateResult evaluate(int loadKey) {
        log.info(() -> "pointsGate evaluate load=" + loadKey);
        List<String> errors = new ArrayList<>();
        ImpIpgLoad load = loadDao.findLoadByKey(loadKey).orElse(null);
        if (load == null) {
            errors.add("Сессия impIpgLoad не найдена: " + loadKey);
            return new ImpIpgPointsGateResult(
                    loadKey, 0, null, 0, 0, false, errors, List.of());
        }
        int ipgKey = load.iilIpg();

        IpgFull ipg = ipgLeavesDao.findIpgByKey(ipgKey).orElse(null);
        if (ipg == null) {
            errors.add("Карточка ipg не найдена: " + ipgKey);
            return new ImpIpgPointsGateResult(
                    loadKey, ipgKey, null, 0, 0, false, errors, List.of());
        }

        int stNetKey = ipg.ipgStRlSh();
        if (stNetKey <= 0) {
            errors.add("У ipg=" + ipgKey + " не задан ipgStRlSh (схема структуры)");
            return new ImpIpgPointsGateResult(
                    loadKey, ipgKey, null, 0, 0, false, errors, List.of());
        }

        ImpIpgReconcileResult reconcile = reconcileService.reconcile(loadKey, stNetKey, false);
        int sectionCount = reconcile.rows().size();
        int openCount = reconcile.open();
        List<Integer> openRowIds = reconcile.rows().stream()
                .filter(row -> !row.closed())
                .map(ImpIpgReconcileRow::rowId)
                .collect(Collectors.toList());

        if (sectionCount == 0) {
            errors.add("В сессии нет разделов ПТСФ (iiRowKind=S); выполните разбор Excel");
        }
        if (openCount > 0) {
            errors.add("ПТСФ не закрыт: open=" + openCount + " из " + sectionCount
                    + " (вернитесь на Structure / сверьте)");
        }

        boolean ready = errors.isEmpty();
        log.info(() -> "pointsGate load=" + loadKey + " ipg=" + ipgKey
                + " stNet=" + stNetKey + " sections=" + sectionCount
                + " open=" + openCount + " ready=" + ready);
        return new ImpIpgPointsGateResult(
                loadKey,
                ipgKey,
                stNetKey,
                sectionCount,
                openCount,
                ready,
                errors,
                openRowIds);
    }

    @Override
    public ImpIpgPointsGateResult assertReady(int loadKey) {
        ImpIpgPointsGateResult result = evaluate(loadKey);
        if (!result.ready()) {
            String message = result.errors().isEmpty()
                    ? "Gate пунктов: сессия " + loadKey + " не готова"
                    : "Gate пунктов: " + String.join("; ", result.errors());
            throw new DaoException(message);
        }
        return result;
    }
}
