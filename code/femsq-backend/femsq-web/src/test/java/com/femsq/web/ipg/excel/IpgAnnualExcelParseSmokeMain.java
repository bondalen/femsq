package com.femsq.web.ipg.excel;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcImpIpgLoadDao;
import com.femsq.database.model.ImpIpgLoad;
import java.nio.file.Path;
import java.util.List;

/**
 * Ручной smoke: парсер Excel → {@code replaceRows} на текущей БД из {@code ~/.femsq/database.properties}.
 */
public final class IpgAnnualExcelParseSmokeMain {

    private IpgAnnualExcelParseSmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        Path excel = Path.of(args.length > 0
                ? args[0]
                : "/mnt/nb-win-share/femsq/excel/2026-1120/ipg-sql-load/sql_0.xlsx");
        int ipgKey = args.length > 1 ? Integer.parseInt(args[1]) : 25;

        DatabaseConfigurationService config = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (ConnectionFactory connections = new ConnectionFactory(config)) {
            JdbcImpIpgLoadDao dao = new JdbcImpIpgLoadDao(connections, config);
            IpgAnnualExcelParser parser = new IpgAnnualExcelParser();
            IpgAnnualExcelParser.ParseOutcome outcome = parser.parse(excel);
            ImpIpgLoad load = dao.insertLoad(
                    ipgKey,
                    "O1 smoke 3.1.6.2 " + excel.getFileName(),
                    excel.toString(),
                    "parser smoke");
            int written = dao.replaceRows(load.iilKey(), outcome.drafts());
            List<?> structure = dao.findStructureRowsByLoad(load.iilKey());
            System.out.println("loadKey=" + load.iilKey()
                    + " sheet=" + outcome.sheetName()
                    + " S=" + outcome.sectionCount()
                    + " L=" + outcome.leafCount()
                    + " written=" + written
                    + " structureRows=" + structure.size());
            dao.deleteLoad(load.iilKey());
            System.out.println("cleaned loadKey=" + load.iilKey());
        }
    }
}
