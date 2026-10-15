package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

/**
 * Узел 3.5: после миграции группы 907 комментарии на Value крайней upl года 901
 * имеют {@code cnicDv} ( Acc-only остаются только без Value на крайних upl).
 */
class CmmDvMigrate907IT {

    private static final int CMM_GR_907 = 907;
    private static final int YR_901 = 901;

    @Test
    void group907CommentsOnYearExtremeHaveDv() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config));
        DatabaseConfigurationService cs = new DatabaseConfigurationService(
                new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory cf = new ConnectionFactory(cs);
             Connection connection = cf.createConnection()) {
            int withDv;
            int accOnlyWithValue;
            String withDvSql = "SELECT COUNT(*) FROM sudz.cnInvCmm WHERE cnicGroup = ? AND cnicDv IS NOT NULL";
            try (PreparedStatement ps = connection.prepareStatement(withDvSql)) {
                ps.setInt(1, CMM_GR_907);
                try (ResultSet rs = ps.executeQuery()) {
                    assertTrue(rs.next());
                    withDv = rs.getInt(1);
                }
            }
            Assumptions.assumeTrue(withDv > 0, "миграция 907 ещё не применена");

            String leftoverSql = ""
                    + "WITH extreme AS ( "
                    + "  SELECT TOP 1 u.upl_key "
                    + "  FROM sudz.yr_upl_p AS yp "
                    + "  INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl "
                    + "  WHERE yp.yr_upl_p_yr = ? "
                    + "  ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC "
                    + ") "
                    + "SELECT COUNT(*) "
                    + "FROM sudz.cnInvCmm AS cm "
                    + "CROSS JOIN extreme AS e "
                    + "WHERE cm.cnicGroup = ? AND cm.cnicDv IS NULL "
                    + "  AND EXISTS ( "
                    + "    SELECT 1 FROM sudz.invDbtDbt AS idd "
                    + "    INNER JOIN sudz.DbtValue AS dv "
                    + "      ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = e.upl_key "
                    + "    WHERE idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt) "
                    + "  )";
            try (PreparedStatement ps = connection.prepareStatement(leftoverSql)) {
                ps.setInt(1, YR_901);
                ps.setInt(2, CMM_GR_907);
                try (ResultSet rs = ps.executeQuery()) {
                    assertTrue(rs.next());
                    accOnlyWithValue = rs.getInt(1);
                }
            }
            assertTrue(accOnlyWithValue == 0,
                    "Acc-only 907 не должны иметь Value на крайней upl 901; leftover="
                            + accOnlyWithValue);
            assertTrue(withDv >= 100, "ожидаются десятки *Dv строк в группе 907, with_dv=" + withDv);
        }
    }
}
