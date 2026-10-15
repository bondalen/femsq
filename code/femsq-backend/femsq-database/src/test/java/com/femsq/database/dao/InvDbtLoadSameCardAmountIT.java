package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.SudzService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

/**
 * Узел 3.1: несколько слотов одной карточки стыкуются по сумме ±0.01
 * без ручного INSERT (А19 на выгрузке 913).
 */
class InvDbtLoadSameCardAmountIT {

    private static final int UNLOAD_913 = 913;
    private static final int IKEY_A19_16343 = 12032;
    private static final int IKEY_A19_16352 = 12033;

    @Test
    void rematchA19SharesOn913ByHistoricalAmount() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs)) {
            Assumptions.assumeTrue(
                    countValues(cf, 901, IKEY_A19_16343) >= 7
                            && countValues(cf, 901, IKEY_A19_16352) >= 5,
                    "нужен эталон сумм А19 на выгрузке 901");

            deleteValues(cf, UNLOAD_913, IKEY_A19_16343);
            deleteValues(cf, UNLOAD_913, IKEY_A19_16352);
            assertEquals(0, countValues(cf, UNLOAD_913, IKEY_A19_16343));
            assertEquals(0, countValues(cf, UNLOAD_913, IKEY_A19_16352));

            SudzService svc = new DefaultSudzService(new JdbcSudzDao(cf, "sudz"));
            SudzDbtUplInvDbtLoadApplyResult result =
                    svc.runInvDbtLoadPhase(UNLOAD_913, null, true);

            int after16343 = countValues(cf, UNLOAD_913, IKEY_A19_16343);
            int after16352 = countValues(cf, UNLOAD_913, IKEY_A19_16352);
            System.out.println("insertedValues=" + result.insertedValues()
                    + " queued=" + result.queuedCount()
                    + " a19_16343=" + after16343
                    + " a19_16352=" + after16352);

            assertEquals(7, after16343, "А19-16343/2021: 7 слотов одной карточки");
            assertEquals(5, after16352, "А19-16352/2021: 5 слотов одной карточки");
            assertTrue(result.insertedValues() >= 12,
                    "ожидали ≥12 новых DbtValue, got=" + result.insertedValues());
            assertTrue(amountsMatchPriorUpl(cf, UNLOAD_913, IKEY_A19_16343));
            assertTrue(amountsMatchPriorUpl(cf, UNLOAD_913, IKEY_A19_16352));
        }
    }

    private static int countValues(ConnectionFactory cf, int upl, int iKey) throws Exception {
        String sql = ""
                + "SELECT COUNT(*) FROM sudz.DbtValue dv "
                + "INNER JOIN sudz.invDbt s ON s.idKey = dv.dvInvDbt "
                + "WHERE dv.dvUpl = ? AND s.idInv = ?";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, upl);
            ps.setInt(2, iKey);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private static void deleteValues(ConnectionFactory cf, int upl, int iKey) throws Exception {
        String sql = ""
                + "DELETE dv FROM sudz.DbtValue dv "
                + "INNER JOIN sudz.invDbt s ON s.idKey = dv.dvInvDbt "
                + "WHERE dv.dvUpl = ? AND s.idInv = ?";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, upl);
            ps.setInt(2, iKey);
            ps.executeUpdate();
        }
    }

    /**
     * Каждая Value 913 на слоте совпадает с исторической (±0.01) на том же слоте.
     */
    private static boolean amountsMatchPriorUpl(ConnectionFactory cf, int upl, int iKey)
            throws Exception {
        String sql = ""
                + "SELECT COUNT(*) AS bad "
                + "FROM sudz.DbtValue cur "
                + "INNER JOIN sudz.invDbt s ON s.idKey = cur.dvInvDbt "
                + "WHERE cur.dvUpl = ? AND s.idInv = ? "
                + "  AND NOT EXISTS ( "
                + "    SELECT 1 FROM sudz.DbtValue hist "
                + "    WHERE hist.dvInvDbt = cur.dvInvDbt "
                + "      AND hist.dvInvDbtVar = cur.dvInvDbtVar "
                + "      AND hist.dvUpl <> ? "
                + "      AND ABS(CAST(hist.dvTtl AS decimal(19,4)) "
                + "             - CAST(cur.dvTtl AS decimal(19,4))) <= 0.01)";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, upl);
            ps.setInt(2, iKey);
            ps.setInt(3, upl);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) == 0;
            }
        }
    }
}
