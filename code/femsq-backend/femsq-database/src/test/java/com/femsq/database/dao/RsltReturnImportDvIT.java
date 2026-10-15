package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzRsltReturnRow;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.SudzService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

/**
 * Узел 3.3: разные тексты полосы Rslt пишутся на разные Value крайней upl.
 */
class RsltReturnImportDvIT {

    private static final int YR_901 = 901;
    private static final int CMM_GR_907 = 907;
    private static final int CNIC_TYPE_MERY = 1;
    private static final String MARK_A = "femsq-3.3-share-a";
    private static final String MARK_B = "femsq-3.3-share-b";

    @Test
    void differentBandTextsWriteToDifferentExtremeValues() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs)) {
            Assumptions.assumeTrue(cmmGrNewIs(cf, YR_901, CMM_GR_907), "yr 901 yr_CmmGr_New=907");
            Sample sample = findSplitDebt(cf, YR_901);
            Assumptions.assumeTrue(sample != null && sample.valueKeys().size() >= 2,
                    "нужен dbt с ≥2 Value на крайней upl года 901");

            int dv0 = sample.valueKeys().get(0);
            int dv1 = sample.valueKeys().get(1);
            String prev0 = readMery(cf, CMM_GR_907, dv0);
            String prev1 = readMery(cf, CMM_GR_907, dv1);

            SudzService svc = new DefaultSudzService(new JdbcSudzDao(cf, "sudz"));
            var imported = svc.importRsltReturn(YR_901, List.of(
                    new SudzRsltReturnRow(sample.dbtKey(), null, MARK_A, null, 0),
                    new SudzRsltReturnRow(sample.dbtKey(), null, MARK_B, null, 1)
            ));
            assertEquals(1, imported.importedDebts());
            assertEquals(1, imported.boundExtreme());
            assertEquals(MARK_A, readMery(cf, CMM_GR_907, dv0));
            assertEquals(MARK_B, readMery(cf, CMM_GR_907, dv1));

            restoreMery(cf, svc, dv0, prev0);
            restoreMery(cf, svc, dv1, prev1);
        }
    }

    private static boolean cmmGrNewIs(ConnectionFactory cf, int yr, int gr) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT yr_CmmGr_New FROM sudz.yr WHERE yr_key = ?")) {
            ps.setInt(1, yr);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) == gr && !rs.wasNull();
            }
        }
    }

    private static Sample findSplitDebt(ConnectionFactory cf, int yrKey) throws Exception {
        String sql = ""
                + "WITH extreme AS ( "
                + "  SELECT TOP 1 u.upl_key "
                + "  FROM sudz.yr_upl_p AS yp "
                + "  INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl "
                + "  WHERE yp.yr_upl_p_yr = ? "
                + "  ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC "
                + "), ranked AS ( "
                + "  SELECT idd.iddDbt AS dbtKey, dv.dvKey, "
                + "         ROW_NUMBER() OVER (PARTITION BY idd.iddDbt ORDER BY s.idNum, s.idKey) AS rn, "
                + "         COUNT(*) OVER (PARTITION BY idd.iddDbt) AS cnt "
                + "  FROM extreme AS e "
                + "  INNER JOIN sudz.DbtValue AS dv ON dv.dvUpl = e.upl_key "
                + "  INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt "
                + "  INNER JOIN sudz.invDbt AS s ON s.idKey = dv.dvInvDbt "
                + ") "
                + "SELECT dbtKey, dvKey FROM ranked WHERE cnt >= 2 AND rn <= 2 "
                + "ORDER BY dbtKey, rn";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, yrKey);
            try (ResultSet rs = ps.executeQuery()) {
                Integer dbt = null;
                List<Integer> values = new ArrayList<>();
                while (rs.next()) {
                    int key = rs.getInt("dbtKey");
                    if (dbt == null) {
                        dbt = key;
                    }
                    if (key != dbt) {
                        break;
                    }
                    values.add(rs.getInt("dvKey"));
                }
                if (dbt == null || values.size() < 2) {
                    return null;
                }
                return new Sample(dbt, List.copyOf(values));
            }
        }
    }

    private static String readMery(ConnectionFactory cf, int gr, int valueKey) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT cnicText FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
            ps.setInt(1, gr);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, valueKey);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getNString(1);
            }
        }
    }

    private static void restoreMery(
            ConnectionFactory cf,
            SudzService svc,
            int valueKey,
            String previous
    ) throws Exception {
        if (previous == null) {
            try (Connection c = cf.createConnection();
                 PreparedStatement ps = c.prepareStatement(
                         "DELETE FROM sudz.cnInvCmm "
                                 + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
                ps.setInt(1, CMM_GR_907);
                ps.setInt(2, CNIC_TYPE_MERY);
                ps.setInt(3, valueKey);
                ps.executeUpdate();
            }
            return;
        }
        svc.upsertDbtCanonComment(valueKey, CMM_GR_907, CNIC_TYPE_MERY, previous);
    }

    private record Sample(int dbtKey, List<Integer> valueKeys) {
    }
}
