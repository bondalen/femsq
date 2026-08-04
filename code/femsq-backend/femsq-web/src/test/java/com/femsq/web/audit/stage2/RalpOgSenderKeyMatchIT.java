package com.femsq.web.audit.stage2;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

/**
 * SQL-симуляция матчинга july staging ↔ domain при каноне {@code onfOg} (как после 0054.7.1 + 0054.7.4).
 *
 * <p>Текущий Docker-домен и staging ещё могут хранить {@code onfKey}; симуляция мапит обе стороны
 * через {@code ogNmF.onfOg} и ожидает full_key ≫ 0 (эталон март∩июль ≈ 420).</p>
 *
 * <p>Запуск:</p>
 * <pre>{@code
 * mvn test -pl femsq-backend/femsq-web -am -Dtest=RalpOgSenderKeyMatchIT \
 *   -Dfemsq.integration.ralpOgSenderKeyMatch=true -Dsurefire.failIfNoSpecifiedTests=false
 * }</pre>
 */
@Tag("integration")
class RalpOgSenderKeyMatchIT {

    /** July staging с 1262 строками (см. chat-plan / exec 1183). */
    private static final long EXEC_JULY = 1183L;
    private static final int YEAR = 2026;
    private static final int EXPECTED_MARCH_OVERLAP = 420;

    @Test
    @EnabledIf("integrationFlagSet")
    void julyStaging_mappedViaOnfOg_matchesDomainOverlap() throws Exception {
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory factory = new ConnectionFactory(cfgService);
             Connection conn = factory.createConnection();
             PreparedStatement ps = conn.prepareStatement("""
                     ;WITH stg AS (
                       SELECT
                         CASE WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX('-', s.ralprtNum) > 0
                           THEN STUFF(s.ralprtNum, CHARINDEX('-', s.ralprtNum), 1, '/')
                           ELSE s.ralprtNum END AS norm_num,
                         CAST(s.ralprtDate AS date) AS dt,
                         s.ralprtCstAgPn AS cst,
                         COALESCE(n.onfOg, CASE WHEN o.ogKey IS NOT NULL THEN s.ralprtOgSender END) AS og
                       FROM ags.ra_stg_ralp s
                       LEFT JOIN ags.ogNmF n ON n.onfKey = s.ralprtOgSender
                       LEFT JOIN ags.og o ON o.ogKey = s.ralprtOgSender
                       WHERE s.ralprt_exec_key = ?
                         AND s.ralprtCstAgPn IS NOT NULL
                         AND s.ralprtOgSender IS NOT NULL
                         AND s.ralprtDate IS NOT NULL
                     ),
                     dom AS (
                       SELECT
                         ra.ralprNum AS num,
                         CAST(ra.ralprDate AS date) AS dt,
                         ra.ralprCstAgPn AS cst,
                         COALESCE(n.onfOg, CASE WHEN o.ogKey IS NOT NULL THEN ra.ralprOgSender END) AS og
                       FROM ags.ralpRa ra
                       LEFT JOIN ags.ogNmF n ON n.onfKey = ra.ralprOgSender
                       LEFT JOIN ags.og o ON o.ogKey = ra.ralprOgSender
                       WHERE ra.ralprY = ?
                     )
                     SELECT
                       (SELECT COUNT(*) FROM stg WHERE og IS NOT NULL) AS stg_with_og,
                       (SELECT COUNT(*) FROM dom WHERE og IS NOT NULL) AS dom_with_og,
                       (SELECT COUNT(*) FROM stg s
                          INNER JOIN dom d ON d.num = s.norm_num AND d.dt = s.dt
                            AND d.cst = s.cst AND d.og = s.og
                          WHERE s.og IS NOT NULL) AS matched_full_key
                     """)) {
            ps.setLong(1, EXEC_JULY);
            ps.setInt(2, YEAR);
            try (ResultSet rs = ps.executeQuery()) {
                org.junit.jupiter.api.Assertions.assertTrue(rs.next());
                int stg = rs.getInt("stg_with_og");
                int dom = rs.getInt("dom_with_og");
                int matched = rs.getInt("matched_full_key");
                org.junit.jupiter.api.Assertions.assertTrue(stg > 1000, "stg_with_og=" + stg);
                org.junit.jupiter.api.Assertions.assertTrue(dom >= EXPECTED_MARCH_OVERLAP, "dom_with_og=" + dom);
                org.junit.jupiter.api.Assertions.assertTrue(
                        matched >= EXPECTED_MARCH_OVERLAP,
                        () -> "matched_full_key=" + matched + " (expected ≥ " + EXPECTED_MARCH_OVERLAP + ")");
            }
        }
    }

    static boolean integrationFlagSet() {
        return Boolean.parseBoolean(System.getProperty("femsq.integration.ralpOgSenderKeyMatch", "false"));
    }
}
