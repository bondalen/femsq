package com.femsq.database.service;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcCstAgPnDao;
import com.femsq.database.dao.JdbcImpIpgLoadDao;
import com.femsq.database.dao.JdbcIpgLeavesDao;
import com.femsq.database.dao.JdbcStIpgStructureDao;
import com.femsq.database.model.ImpIpgPointsApplyResult;
import com.femsq.database.model.ImpIpgPointsGateResult;
import com.femsq.database.model.ImpIpgShResolveResult;
import com.femsq.database.model.ImpIpgStiInheritResult;

/**
 * Сводка готовности к apply по списку load (gate / sti / sh / dryRun).
 *
 * <p>Args: loadKeys через пробел; по умолчанию 8 9 10 11.
 */
public final class ImpIpgPointsReadinessSmokeMain {

    private ImpIpgPointsReadinessSmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        int[] loads = args.length == 0
                ? new int[]{8, 9, 10, 11}
                : java.util.Arrays.stream(args).mapToInt(Integer::parseInt).toArray();

        DatabaseConfigurationService config = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (ConnectionFactory connections = new ConnectionFactory(config)) {
            JdbcImpIpgLoadDao loadDao = new JdbcImpIpgLoadDao(connections, config);
            JdbcIpgLeavesDao leavesDao = new JdbcIpgLeavesDao(connections, config);
            JdbcCstAgPnDao cstAgPnDao = new JdbcCstAgPnDao(connections, config);
            JdbcStIpgStructureDao structureDao = new JdbcStIpgStructureDao(connections, config);

            ImpIpgReconcileService reconcile = new DefaultImpIpgReconcileService(loadDao, structureDao);
            ImpIpgPointsGateService gate = new DefaultImpIpgPointsGateService(loadDao, leavesDao, reconcile);
            ImpIpgStiInheritService sti = new DefaultImpIpgStiInheritService(loadDao);
            ImpIpgShResolveService sh = new DefaultImpIpgShResolveService(loadDao, leavesDao);
            ImpIpgPointsApplyService apply = new DefaultImpIpgPointsApplyService(
                    loadDao, leavesDao, cstAgPnDao, gate, sti, sh);

            for (int loadKey : loads) {
                ImpIpgPointsGateResult g = gate.evaluate(loadKey);
                ImpIpgStiInheritResult s = sti.evaluate(loadKey);
                ImpIpgShResolveResult h = sh.evaluate(loadKey, null);
                ImpIpgPointsApplyResult a = apply.apply(loadKey, null, true);
                System.out.printf(
                        "load=%d ipg=%d | gate=%s open=%d/%d | sti=%s ready=%d hole=%d | sh=%s ok=%d err=%d | dryRun=%s applied=%d errs=%s%n",
                        loadKey,
                        g.ipgKey(),
                        g.ready(),
                        g.openCount(),
                        g.sectionCount(),
                        s.ready(),
                        s.readyCount(),
                        s.holeCount(),
                        h.ready(),
                        h.resolvedCount(),
                        h.errorCount(),
                        a.ready(),
                        a.appliedCount(),
                        a.errors());
            }
        }
    }
}
