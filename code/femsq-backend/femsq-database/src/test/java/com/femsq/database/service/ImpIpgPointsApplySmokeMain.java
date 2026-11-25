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

/**
 * Smoke apply пунктов (§3.2.4 / §3.2.7 partial).
 *
 * <p>Args: {@code [loadKey] [previousIpgKey|none] [dryRun|commit]}
 * Defaults: load=8, prev=none, dryRun.
 *
 * <p>Exit 0 — ready или частичный успех (applied/skippedAlready &gt; 0).
 * Exit 2 — полный провал (ничего не применено и есть ошибки).
 */
public final class ImpIpgPointsApplySmokeMain {

    private ImpIpgPointsApplySmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        int loadKey = args.length > 0 ? Integer.parseInt(args[0]) : 8;
        Integer previousIpgKey = null;
        if (args.length > 1 && !"none".equalsIgnoreCase(args[1]) && !"-".equals(args[1])) {
            previousIpgKey = Integer.parseInt(args[1]);
        }
        boolean dryRun = args.length < 3 || !"commit".equalsIgnoreCase(args[2]);

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

            ImpIpgPointsApplyResult result = apply.apply(loadKey, previousIpgKey, dryRun);
            System.out.println("loadKey=" + result.loadKey()
                    + " ipgKey=" + result.ipgKey()
                    + " prev=" + result.previousIpgKey()
                    + " dryRun=" + result.dryRun()
                    + " leafCount=" + result.leafCount()
                    + " appliedCount=" + result.appliedCount()
                    + " skippedAlready=" + result.skippedAlreadyCount()
                    + " ready=" + result.ready()
                    + " created=" + result.createdPnKeys().size()
                    + " errors=" + result.errors().size()
                    + " problemRows=" + result.problemRowIds().size());
            for (String err : result.errors()) {
                System.out.println("ERR " + err);
            }
            boolean ok = result.ready()
                    || result.appliedCount() > 0
                    || result.skippedAlreadyCount() > 0;
            if (!ok) {
                System.exit(2);
            }
        }
    }
}
