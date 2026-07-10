package com.femsq.web.audit.reconcile;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

/**
 * Smoke reconcile RALP (type=3) на dev БД без полного executeAudit: dry-run март/июль + apply июль.
 *
 * <p>Использует существующий staging exec_key=1152 (март) и 1156 (июль). Предусловие: домен
 * {@code ralpRa_2026=420}, {@code ralpRaAu_2026=408}.</p>
 *
 * <p>Запуск:</p>
 * <pre>{@code
 * mvn test -pl femsq-backend/femsq-web -am -Dtest=RalpReconcileApplySmokeIT \
 *   -Dfemsq.integration.ralpApplySmoke=true -Dsurefire.failIfNoSpecifiedTests=false
 * }</pre>
 */
@Tag("integration")
class RalpReconcileApplySmokeIT {

    private static final int AUDIT_ID = 14;
    private static final int FILE_TYPE = 3;
    private static final long EXEC_MARCH = 1152L;
    private static final long EXEC_JULY = 1156L;

    @Test
    @EnabledIf("integrationFlagSet")
    void marchDryRun_julyDryRun_julyApply_shouldMatchExpectedCounts() throws Exception {
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        Path restoreScript = Path.of(System.getProperty("user.dir"))
                .resolve("../../scripts/restore-ralp-march-baseline-from-staging.sql")
                .normalize();

        try (ConnectionFactory factory = new ConnectionFactory(cfgService)) {
            ensureMarchBaseline(factory, restoreScript);

            RalpReconcileService service = new RalpReconcileService(factory);

            ReconcileResult marchDry = service.reconcile(new ReconcileContext(EXEC_MARCH, AUDIT_ID, false, FILE_TYPE));
            org.junit.jupiter.api.Assertions.assertFalse(marchDry.applied(), marchDry.message());

            DomainCounts afterMarchDry = readDomainCounts(factory);
            org.junit.jupiter.api.Assertions.assertEquals(420, afterMarchDry.ralpRa2026());
            org.junit.jupiter.api.Assertions.assertEquals(408, afterMarchDry.ralpRaAu2026());

            ReconcileResult julyDry = service.reconcile(new ReconcileContext(EXEC_JULY, AUDIT_ID, false, FILE_TYPE));
            org.junit.jupiter.api.Assertions.assertFalse(julyDry.applied(), julyDry.message());
            org.junit.jupiter.api.Assertions.assertTrue(
                    julyDry.message().contains("raInserted=828"),
                    () -> "july dry-run: " + julyDry.message());

            ReconcileResult julyApply = service.reconcile(new ReconcileContext(EXEC_JULY, AUDIT_ID, true, FILE_TYPE));
            org.junit.jupiter.api.Assertions.assertTrue(julyApply.applied(), julyApply.message());

            DomainCounts afterApply = readDomainCounts(factory);
            org.junit.jupiter.api.Assertions.assertEquals(1248, afterApply.ralpRa2026());
            org.junit.jupiter.api.Assertions.assertEquals(1248, afterApply.ralpRaAu2026());

            String msg = julyApply.message();
            org.junit.jupiter.api.Assertions.assertTrue(msg.contains("raInserted=828"), msg);
            org.junit.jupiter.api.Assertions.assertTrue(msg.contains("auDemotedSent=0"), msg);
            org.junit.jupiter.api.Assertions.assertTrue(msg.contains("auClosedInProcess=0"), msg);

            int multiSent = readIntViaFactory(factory,
                    """
                    SELECT COUNT(*) FROM (
                      SELECT a.ralpraRa FROM ags.ralpRaAu a
                      JOIN ags.ralpRa r ON r.ralprKey = a.ralpraRa
                      WHERE r.ralprY = 2026
                        AND a.ralpraSent IS NOT NULL AND LTRIM(RTRIM(a.ralpraSent)) <> N''
                      GROUP BY a.ralpraRa HAVING COUNT(*) > 1
                    ) x
                    """);
            org.junit.jupiter.api.Assertions.assertEquals(0, multiSent, "не более одного sent на ralpRa");

            restoreMarchBaseline(factory, restoreScript);
            DomainCounts afterRestore = readDomainCounts(factory);
            org.junit.jupiter.api.Assertions.assertEquals(420, afterRestore.ralpRa2026());
            org.junit.jupiter.api.Assertions.assertEquals(408, afterRestore.ralpRaAu2026());
        }
    }

    private static void ensureMarchBaseline(ConnectionFactory factory, Path restoreScript) throws Exception {
        DomainCounts counts = readDomainCounts(factory);
        if (counts.ralpRa2026() == 420 && counts.ralpRaAu2026() == 408) {
            return;
        }
        restoreMarchBaseline(factory, restoreScript);
    }

    private static void restoreMarchBaseline(ConnectionFactory factory, Path restoreScript) throws Exception {
        if (!Files.isRegularFile(restoreScript)) {
            throw new IllegalStateException("Не найден restore script: " + restoreScript.toAbsolutePath());
        }
        String sql = Files.readString(restoreScript, StandardCharsets.UTF_8);
        try (Connection connection = factory.createConnection()) {
            connection.setAutoCommit(true);
            try (var st = connection.createStatement()) {
                st.execute(sql);
            }
        }
    }

    private static DomainCounts readDomainCounts(ConnectionFactory factory) throws Exception {
        try (Connection c = factory.createConnection()) {
            int ra = readInt(c, "SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026");
            int au = readInt(c,
                    """
                    SELECT COUNT(*) FROM ags.ralpRaAu au
                    JOIN ags.ralpRa r ON au.ralpraRa = r.ralprKey
                    WHERE r.ralprY = 2026
                    """);
            return new DomainCounts(ra, au);
        }
    }

    private static int readIntViaFactory(ConnectionFactory factory, String sql) throws Exception {
        try (Connection c = factory.createConnection()) {
            return readInt(c, sql);
        }
    }

    private static int readInt(Connection connection, String sql) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                throw new IllegalStateException("No rows: " + sql);
            }
            return rs.getInt(1);
        }
    }

    @SuppressWarnings("unused")
    static boolean integrationFlagSet() {
        return Boolean.parseBoolean(System.getProperty("femsq.integration.ralpApplySmoke", "false"));
    }

    private record DomainCounts(int ralpRa2026, int ralpRaAu2026) {
    }
}
