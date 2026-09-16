package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadCalmRow;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.SudzService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

/** B2: dry invDbtLoad @902 показывает Calm Create для 4 iKey без слота. */
class InvDbtLoadDryCalmCreateIT {

    private static final Set<Integer> EXPECTED_IKEYS = Set.of(92012, 92013, 92014, 92015);

    @Test
    void dryPhaseListsMissingSlotsAsCalmCreate() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs)) {
            SudzService svc = new DefaultSudzService(new JdbcSudzDao(cf, "sudz"));
            SudzDbtUplInvDbtLoadApplyResult result = svc.runInvDbtLoadPhase(902, null, false);
            Set<Integer> calmIKeys = result.calmCreatePending().stream()
                    .map(SudzDbtUplInvDbtLoadCalmRow::iKey)
                    .collect(Collectors.toSet());
            System.out.println("calmCreate=" + result.calmCreatePending().size()
                    + " calmF1=" + result.calmF1Pending().size()
                    + " silentHole=" + result.silentHoleResolved().size()
                    + " queued=" + result.queuedCount());
            for (Integer iKey : EXPECTED_IKEYS) {
                assertTrue(calmIKeys.contains(iKey), "ожидали iKey=" + iKey + " в Calm Create, got=" + calmIKeys);
            }
        }
    }
}
