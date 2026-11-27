package com.femsq.database.service;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.dao.JdbcIpgUtPlDao;
import com.femsq.database.model.IpgUtPl;
import com.femsq.database.model.IpgUtPlPnLmMnGrid;
import com.femsq.database.model.IpgUtPlPnLmMnMonth;
import java.math.BigDecimal;
import java.util.List;

/**
 * Приёмка §4.2: list UtPl by ipg, load LmMn grid, upsert month + G-agg + cleanup.
 *
 * <p>Запуск из {@code femsq-database}: {@code mvn -q exec:java
 * -Dexec.mainClass=com.femsq.database.service.IpgUtPlLmMnSmokeMain
 * -Dexec.classpathScope=test}
 */
public final class IpgUtPlLmMnSmokeMain {

    private static final int IPG = 11;
    private static final int PL = 203;
    private static final int PN = 5473;

    private IpgUtPlLmMnSmokeMain() {
    }

    public static void main(String[] args) throws Exception {
        DatabaseConfigurationService config = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator());
        try (ConnectionFactory connections = new ConnectionFactory(config)) {
            IpgUtPlService service = new DefaultIpgUtPlService(
                    new JdbcIpgUtPlDao(connections, config));

            List<IpgUtPl> plans = service.listUtPlByIpg(IPG);
            System.out.println("ipgUtPlByIpg(" + IPG + ")=" + plans.size());
            if (plans.stream().noneMatch(p -> p.iuplKey() == PL)) {
                throw new IllegalStateException("Ожидался план " + PL + " на ipg " + IPG);
            }

            IpgUtPlPnLmMnGrid before = service.loadLmMnGrid(PL, PN);
            System.out.println("grid plPn=" + before.plPnKey()
                    + " limYear=" + before.limYear()
                    + " cells=" + before.cells().size()
                    + " gAggOk=" + before.gAggOk());

            IpgUtPlPnLmMnMonth m1 = before.months().stream()
                    .filter(m -> m.month() == 1)
                    .findFirst()
                    .orElseThrow();
            BigDecimal old212 = m1.lim212();
            BigDecimal old187 = m1.lim187();

            BigDecimal smoke212 = new BigDecimal("1.23456789");
            BigDecimal smoke187 = new BigDecimal("1.23456789");
            IpgUtPlPnLmMnGrid after = service.upsertLmMnMonth(
                    PL, PN, 1, smoke212, null, null, smoke187);
            System.out.println("after upsert m1 gAggOk=" + after.gAggOk()
                    + " limYear=" + after.limYear());
            if (!after.gAggOk()) {
                throw new IllegalStateException("G-agg failed after upsert");
            }
            IpgUtPlPnLmMnMonth saved = after.months().stream()
                    .filter(m -> m.month() == 1)
                    .findFirst()
                    .orElseThrow();
            if (saved.lim212() == null
                    || saved.lim212().compareTo(smoke212) != 0) {
                throw new IllegalStateException("lim212 not persisted: " + saved.lim212());
            }

            // restore
            service.upsertLmMnMonth(PL, PN, 1, old212, null, null, old187);
            System.out.println("restored m1; PASS");
        }
    }
}
