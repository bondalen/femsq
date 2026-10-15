package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzDbtCanonDetail;
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
 * Узел 3.2: запись комментария якорит {@code cnicDv}; {@code cnicDbt} выводится из Value.
 */
class CmmDvWriteIT {

    private static final int CMM_GR_907 = 907;
    private static final int CNIC_TYPE_MERY = 1;
    private static final String MARKER = "femsq-3.2-cmm-dv-smoke";

    @Test
    void upsertCommentWritesDvAndDerivedDbt() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs)) {
            Sample sample = findSample(cf);
            Assumptions.assumeTrue(sample != null, "нет Value на срезе группы 907");

            SudzService svc = new DefaultSudzService(new JdbcSudzDao(cf, "sudz"));
            SudzDbtCanonDetail detail = svc.upsertDbtCanonComment(
                    sample.valueKey(), CMM_GR_907, CNIC_TYPE_MERY, MARKER);
            assertEquals(sample.dbtKey(), detail.dbtKey());

            try (Connection c = cf.createConnection();
                 PreparedStatement ps = c.prepareStatement(
                         "SELECT cnicDv, cnicDbt, cnicInvAccnt, cnicText FROM sudz.cnInvCmm "
                                 + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
                ps.setInt(1, CMM_GR_907);
                ps.setInt(2, CNIC_TYPE_MERY);
                ps.setInt(3, sample.valueKey());
                try (ResultSet rs = ps.executeQuery()) {
                    assertTrue(rs.next(), "строка cnInvCmm с cnicDv");
                    assertEquals(sample.valueKey(), rs.getInt("cnicDv"));
                    assertEquals(sample.dbtKey(), rs.getInt("cnicDbt"));
                    assertEquals(sample.dbtKey(), rs.getInt("cnicInvAccnt"));
                    assertEquals(MARKER, rs.getNString("cnicText"));
                }
            }

            // откат маркера: вернуть прежний текст или удалить, если строки не было
            if (sample.previousText() == null && !sample.hadRow()) {
                svc.deleteDbtCanonComment(findCmmKey(cf, sample.valueKey()));
            } else {
                svc.upsertDbtCanonComment(
                        sample.valueKey(),
                        CMM_GR_907,
                        CNIC_TYPE_MERY,
                        sample.previousText() == null ? "" : sample.previousText());
            }
        }
    }

    private static Sample findSample(ConnectionFactory cf) throws Exception {
        String sql = ""
                + "SELECT TOP 1 dv.dvKey, idd.iddDbt AS dbtKey, cm.cnicText, "
                + "       CASE WHEN cm.cnicKey IS NULL THEN 0 ELSE 1 END AS hadRow "
                + "FROM sudz.yr AS y "
                + "INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key "
                + "INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl "
                + "INNER JOIN sudz.DbtValue AS dv ON dv.dvUpl = u.upl_key "
                + "INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt "
                + "LEFT JOIN sudz.cnInvCmm AS cm "
                + "  ON cm.cnicGroup = ? AND cm.cnicType = ? AND cm.cnicDv = dv.dvKey "
                + "WHERE y.yr_CmmGr = ? OR y.yr_CmmGr_New = ? "
                + "ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, "
                + "         CASE WHEN cm.cnicKey IS NULL THEN 0 ELSE 1 END, dv.dvKey";
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, CMM_GR_907);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, CMM_GR_907);
            ps.setInt(4, CMM_GR_907);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new Sample(
                        rs.getInt("dvKey"),
                        rs.getInt("dbtKey"),
                        rs.getNString("cnicText"),
                        rs.getInt("hadRow") == 1);
            }
        }
    }

    private static int findCmmKey(ConnectionFactory cf, int valueKey) throws Exception {
        try (Connection c = cf.createConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT cnicKey FROM sudz.cnInvCmm "
                             + "WHERE cnicGroup = ? AND cnicType = ? AND cnicDv = ?")) {
            ps.setInt(1, CMM_GR_907);
            ps.setInt(2, CNIC_TYPE_MERY);
            ps.setInt(3, valueKey);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                int key = rs.getInt(1);
                assertNotNull(key);
                return key;
            }
        }
    }

    private record Sample(int valueKey, int dbtKey, String previousText, boolean hadRow) {
    }
}
