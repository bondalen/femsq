package com.femsq.web.ipg.excel;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcImpIpgLoadDao;
import com.femsq.database.dao.JdbcStIpgStructureDao;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgReconcileResult;
import com.femsq.database.model.ImpIpgReconcileStatus;
import com.femsq.database.service.DefaultImpIpgReconcileService;
import java.nio.file.Path;
import java.util.EnumMap;
import java.util.Map;

/**
 * Smoke: parse sql_0 → reconcile against stNet (default 2).
 */
public final class IpgReconcileSmokeMain {

    private IpgReconcileSmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        Path excel = Path.of(args.length > 0
                ? args[0]
                : "/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_0.xlsx");
        int ipgKey = args.length > 1 ? Integer.parseInt(args[1]) : 25;
        int stNetKey = args.length > 2 ? Integer.parseInt(args[2]) : 2;

        DatabaseConfigurationService config = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (ConnectionFactory connections = new ConnectionFactory(config)) {
            JdbcImpIpgLoadDao loadDao = new JdbcImpIpgLoadDao(connections, config);
            JdbcStIpgStructureDao structureDao = new JdbcStIpgStructureDao(connections, config);
            IpgAnnualExcelParser parser = new IpgAnnualExcelParser();
            var outcome = parser.parse(excel);
            ImpIpgLoad load = loadDao.insertLoad(
                    ipgKey,
                    "O1 smoke 3.1.6.3 " + excel.getFileName(),
                    excel.toString(),
                    "reconcile smoke");
            loadDao.replaceRows(load.iilKey(), outcome.drafts());
            ImpIpgReconcileResult result = new DefaultImpIpgReconcileService(loadDao, structureDao)
                    .reconcile(load.iilKey(), stNetKey, true);
            Map<ImpIpgReconcileStatus, Integer> counts = new EnumMap<>(ImpIpgReconcileStatus.class);
            for (var row : result.rows()) {
                counts.merge(row.status(), 1, Integer::sum);
            }
            System.out.println("loadKey=" + load.iilKey()
                    + " stNet=" + stNetKey
                    + " S=" + outcome.sectionCount()
                    + " matched=" + result.matched()
                    + " open=" + result.open()
                    + " byStatus=" + counts);
            loadDao.deleteLoad(load.iilKey());
            System.out.println("cleaned loadKey=" + load.iilKey());
        }
    }
}
