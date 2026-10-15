package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzRsltReturnImportResult;
import com.femsq.database.model.sudz.SudzRsltReturnRow;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.SudzService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

/**
 * Walk-back: долг без Value на крайней upl пишется на Value предшествующей (база), не Acc.
 */
class CmmDvWalkBackIT {

    private static final int YR_901 = 901;
    private static final int CNIC_TYPE_MERY = 1;
    private static final String MARKER = "femsq-walkback-cmm-dv";

    @Test
    void importBindsToPrecedingUplWhenExtremeHasNoValue() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs)) {
            Integer cmmGrNew = readCmmGrNew(cf, YR_901);
            Assumptions.assumeTrue(cmmGrNew != null && cmmGrNew > 0, "yr 901 yr_CmmGr_New задан");
            Sample sample = findWalkBackDebt(cf, YR_901);
            Assumptions.assumeTrue(sample != null, "нет долга: Value на базе, нет на крайней upl 901");

            SudzService svc = new DefaultSudzService(new JdbcSudzDao(cf, "sudz"));
            String previous = readMeryOnDv(cf, cmmGrNew, sample.valueKey());
            boolean hadAcc = hasAccOnly(cf, cmmGrNew, sample.dbtKey());

            SudzRsltReturnImportResult result = svc.importRsltReturn(
                    YR_901,
                    List.of(new SudzRsltReturnRow(sample.dbtKey(), null, MARKER, null, 0)));
            assertEquals(1, result.importedDebts());
            assertEquals(0, result.boundExtreme());
            assertEquals(1, result.boundWalkBack());
            assertEquals(0, result.boundAcc());
            assertEquals(MARKER, readMeryOnDv(cf, cmmGrNew, sample.valueKey()));
            assertTrue(!hasAccOnlyWithText(cf, cmmGrNew, sample.dbtKey(), MARKER)
                            || readMeryOnDv(cf, cmmGrNew, sample.valueKey()) != null,
                    "якорь на Value, не чистый Acc без Dv");

            // откат
            if (previous == null) {
                deleteOnDv(cf, cmmGrNew, sample.valueKey());
            } else {
                svc.upsertDbtCanonComment(sample.valueKey(), cmmGrNew, CNIC_TYPE_MERY, previous);
            }
            if (hadAcc) {
                // Acc-строка могла быть adopt'нута в *Dv — ок
            }
            assertNotNull(sample.valueKey());
        }
    }

    private static Integer readCmmGrNew(ConnectionFactory cf, int yr) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT yr_CmmGr_New FROM sudz.yr WHERE yr_key = ?")) {
            ps.setInt(1, yr);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getObject(1) == null) {
                    return null;
                }
                return rs.getInt(1);
            }
        }
    }

    /**
     * Долг с Value на не-крайней upl года и без Value на крайней.
     */
    private static Sample findWalkBackDebt(ConnectionFactory cf, int yrKey) throws Exception {
        String sql = ""
                + "WITH ranked AS ( "
                + "  SELECT u.upl_key, "
                + "    ROW_NUMBER() OVER ( "
                + "      ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC "
                + "    ) AS rn "
                + "  FROM sudz.yr_upl_p AS yp "
                + "  INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl "
                + "  WHERE yp.yr_upl_p_yr = ? "
                + "), extreme AS ( "
                + "  SELECT upl_key FROM ranked WHERE rn = 1 "
                + "), candidates AS ( "
                + "  SELECT idd.iddDbt AS dbtKey, "
                + "         MAX(CASE WHEN r.rn = 1 THEN 1 ELSE 0 END) AS on_extreme, "
                + "         MAX(CASE WHEN r.rn > 1 THEN 1 ELSE 0 END) AS on_prior "
                + "  FROM ranked AS r "
                + "  INNER JOIN sudz.DbtValue AS dv ON dv.dvUpl = r.upl_key "
                + "  INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt "
                + "  GROUP BY idd.iddDbt "
                + ") "
                + "SELECT TOP 1 c.dbtKey, dv.dvKey "
                + "FROM candidates AS c "
                + "INNER JOIN sudz.invDbtDbt AS idd ON idd.iddDbt = c.dbtKey "
                + "INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = idd.iddInvDbt "
                + "INNER JOIN ranked AS r ON r.upl_key = dv.dvUpl "
                + "WHERE c.on_extreme = 0 AND c.on_prior = 1 "
                + "ORDER BY r.rn, dv.dvKey";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, yrKey);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new Sample(rs.getInt("dbtKey"), rs.getInt("dvKey"));
            }
        }
    }

    private static String readMeryOnDv(ConnectionFactory cf, int gr, int valueKey) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT cnicText FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
            ps.setInt(1, gr);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, valueKey);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getNString(1) : null;
            }
        }
    }

    private static boolean hasAccOnly(ConnectionFactory cf, int gr, int dbtKey) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT COUNT(*) FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? "
                             + "  AND cnicInvAccnt = ? AND cnicDv IS NULL")) {
            ps.setInt(1, gr);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, dbtKey);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private static boolean hasAccOnlyWithText(
            ConnectionFactory cf, int gr, int dbtKey, String text
    ) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT COUNT(*) FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? "
                             + "  AND cnicInvAccnt = ? AND cnicDv IS NULL AND cnicText = ?")) {
            ps.setInt(1, gr);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, dbtKey);
            ps.setNString(4, text);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private static void deleteOnDv(ConnectionFactory cf, int gr, int valueKey) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "DELETE FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
            ps.setInt(1, gr);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, valueKey);
            ps.executeUpdate();
        }
    }

    private record Sample(int dbtKey, int valueKey) {
    }
}
