package com.femsq.web.audit.reconcile;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.Duration;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

/**
 * 1.5.5 Проверка поведения при частичном сбое: rollback и повторный безопасный запуск.
 *
 * <p>Запуск (вручную, при запущенном приложении на localhost:8080):</p>
 * <pre>{@code
 * mvn test -pl femsq-web -Dtest=Type5PartialFailureRecoveryIntegrationIT -Dfemsq.integration.type5FailureRecovery=true
 * }</pre>
 */
@Tag("integration")
class Type5PartialFailureRecoveryIntegrationIT {

    private static final int AUDIT_ID = 14;
    private static final int FILE_TYPE = 5;
    private static final String FAILURE_PROP = "femsq.reconcile.type5.simulateFailureStep";

    @Test
    @EnabledIf("integrationFlagSet")
    void reconcile_failureAfterRa_shouldRollbackAndAllowSafeRetry() throws Exception {
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory factory = new ConnectionFactory(cfgService);
                Connection connection = factory.createConnection()) {

            connection.setAutoCommit(false);
            int prevAddRa = readInt(connection, "SELECT CAST(adt_AddRA AS int) FROM ags.ra_a WHERE adt_key = ?", AUDIT_ID);
            int baselineRaMax = readInt(connection, "SELECT ISNULL(MAX(ra_key), 0) FROM ags.ra");
            int baselineRasMax = readInt(connection, "SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ");
            int baselineRacMax = readInt(connection, "SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change");
            int baselineRacsMax = readInt(connection, "SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ");
            ensureMarkerTableExists(connection);
            long baselineRmMax = readLong(connection, "SELECT ISNULL(MAX(rm_key), 0) FROM ags.ra_reconcile_marker");

            try {
                // 1) Сначала запускаем audit в dry-run, чтобы получить exec_key + staging без изменений домена.
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = 0 WHERE adt_key = ?", AUDIT_ID);
                connection.commit();

                executeAuditViaGraphql(AUDIT_ID);
                long execKey = waitForCompletedAndGetExecKey(factory, AUDIT_ID, Duration.ofSeconds(180));

                AllAgentsReconcileService service = new AllAgentsReconcileService(factory);

                // Baseline после staging (домен не должен меняться при dry-run).
                DomainSnapshot baselineDomain = domainSnapshot(factory);
                long baselineMarkerForExec = readLong(factory,
                        "SELECT COUNT(*) FROM ags.ra_reconcile_marker WHERE exec_key = ?",
                        execKey);

                // 1) Simulate failure after RA apply step.
                System.setProperty(FAILURE_PROP, "TYPE5_APPLY_RA");
                try {
                    service.reconcile(new ReconcileContext(execKey, AUDIT_ID, true, FILE_TYPE));
                    org.junit.jupiter.api.Assertions.fail("expected simulated failure");
                } catch (RuntimeException ex) {
                    // ok (wrapped SQL exception)
                } finally {
                    System.clearProperty(FAILURE_PROP);
                }

                // 2) Verify rollback: no new domain keys and no markers for this execKey.
                DomainSnapshot afterFail = domainSnapshot(factory);
                org.junit.jupiter.api.Assertions.assertEquals(
                        baselineDomain,
                        afterFail,
                        "expected rollback after failure (no new domain rows)");
                long markerCount = readLong(factory, "SELECT COUNT(*) FROM ags.ra_reconcile_marker WHERE exec_key = ?", execKey);
                org.junit.jupiter.api.Assertions.assertEquals(baselineMarkerForExec, markerCount, "expected no markers after rollback");

                // 3) Retry: should apply successfully.
                service.reconcile(new ReconcileContext(execKey, AUDIT_ID, true, FILE_TYPE));
                long markerCountAfter = readLong(factory, "SELECT COUNT(*) FROM ags.ra_reconcile_marker WHERE exec_key = ?", execKey);
                org.junit.jupiter.api.Assertions.assertTrue(markerCountAfter >= 1, "expected markers after successful retry");

                // 4) Repeat: must be idempotent on same exec_key.
                DomainSnapshot afterApply = domainSnapshot(factory);
                service.reconcile(new ReconcileContext(execKey, AUDIT_ID, true, FILE_TYPE));
                DomainSnapshot afterSecondApply = domainSnapshot(factory);
                org.junit.jupiter.api.Assertions.assertEquals(afterApply, afterSecondApply, "expected idempotent retry on same exec_key");
            } finally {
                try (Connection cleanup = factory.createConnection()) {
                    cleanup.setAutoCommit(false);
                    exec(cleanup, "DELETE FROM ags.ra_summ WHERE ras_key > ?", baselineRasMax);
                    exec(cleanup, "DELETE FROM ags.ra WHERE ra_key > ?", baselineRaMax);
                    exec(cleanup, "DELETE FROM ags.ra_change_summ WHERE [raсs_key] > ?", baselineRacsMax);
                    exec(cleanup, "DELETE FROM ags.ra_change WHERE rac_key > ?", baselineRacMax);
                    exec(cleanup, "DELETE FROM ags.ra_reconcile_marker WHERE rm_key > ?", baselineRmMax);
                    exec(cleanup, "UPDATE ags.ra_a SET adt_AddRA = ? WHERE adt_key = ?", prevAddRa, AUDIT_ID);
                    cleanup.commit();
                }
            }
        }
    }

    private static DomainSnapshot domainSnapshot(ConnectionFactory factory) throws Exception {
        try (Connection c = factory.createConnection()) {
            return new DomainSnapshot(
                    readInt(c, "SELECT ISNULL(MAX(ra_key), 0) FROM ags.ra"),
                    readInt(c, "SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ"),
                    readInt(c, "SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change"),
                    readInt(c, "SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ")
            );
        }
    }

    private static long readLong(ConnectionFactory factory, String sql, Object... params) throws Exception {
        try (Connection c = factory.createConnection()) {
            return readLong(c, sql, params);
        }
    }

    private static long waitForCompletedAndGetExecKey(ConnectionFactory factory, int auditId, Duration timeout) throws Exception {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            try (Connection c = factory.createConnection()) {
                long latest = readLong(c,
                        "SELECT TOP 1 exec_key FROM ags.ra_execution WHERE exec_adt_key = ? ORDER BY exec_key DESC",
                        auditId);
                String status = readString(c,
                        "SELECT TOP 1 exec_status FROM ags.ra_execution WHERE exec_key = ?",
                        latest);
                if ("COMPLETED".equalsIgnoreCase(status) || "FAILED".equalsIgnoreCase(status)) {
                    org.junit.jupiter.api.Assertions.assertEquals("COMPLETED", status, "execution failed for exec_key=" + latest);
                    return latest;
                }
            }
            Thread.sleep(1500);
        }
        throw new IllegalStateException("Timeout waiting for audit " + auditId + " completion");
    }

    private static void executeAuditViaGraphql(int auditId) throws Exception {
        String payload = "{\"query\":\"mutation { executeAudit(id: " + auditId
                + ") { started alreadyRunning message } }\"}";
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:8080/graphql"))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();
        HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IllegalStateException("GraphQL returned " + response.statusCode() + ": " + response.body());
        }
    }

    private static void ensureMarkerTableExists(Connection connection) throws Exception {
        String sql = """
                IF OBJECT_ID(N'ags.ra_reconcile_marker', N'U') IS NULL
                BEGIN
                    CREATE TABLE ags.ra_reconcile_marker (
                        rm_key BIGINT IDENTITY(1,1) PRIMARY KEY,
                        exec_key BIGINT NOT NULL,
                        file_type INT NOT NULL,
                        step_code NVARCHAR(64) NOT NULL,
                        created_at DATETIME2 NOT NULL CONSTRAINT DF_ra_reconcile_marker_created_at DEFAULT SYSUTCDATETIME(),
                        details NVARCHAR(4000) NULL
                    );
                    CREATE UNIQUE INDEX UX_ra_reconcile_marker_exec_step
                        ON ags.ra_reconcile_marker(exec_key, file_type, step_code);
                    CREATE INDEX IX_ra_reconcile_marker_created_at
                        ON ags.ra_reconcile_marker(created_at);
                END
                """;
        exec(connection, sql);
    }

    private static void exec(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }

    private static int readInt(Connection connection, String sql, Object... params) throws Exception {
        return (int) readLong(connection, sql, params);
    }

    private static long readLong(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalStateException("No rows for query: " + sql);
                }
                return rs.getLong(1);
            }
        }
    }

    private static String readString(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalStateException("No rows for query: " + sql);
                }
                return rs.getString(1);
            }
        }
    }

    @SuppressWarnings("unused")
    static boolean integrationFlagSet() {
        return Boolean.parseBoolean(System.getProperty("femsq.integration.type5FailureRecovery", "false"));
    }

    private record DomainSnapshot(int raMax, int rasMax, int racMax, int racsMax) {
    }
}

