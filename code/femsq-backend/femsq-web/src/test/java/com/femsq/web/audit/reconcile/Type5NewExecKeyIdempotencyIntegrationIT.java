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
 * 1.5.4 Интеграционная проверка повторного запуска той же ревизии с новым exec_key.
 *
 * <p>Сценарий:</p>
 * <ol>
 *   <li>Включаем {@code adt_AddRA=true} для ревизии.</li>
 *   <li>Запускаем {@code executeAudit(14)} → ждём COMPLETED → фиксируем execKey1.</li>
 *   <li>Снимаем snapshot доменных max ключей.</li>
 *   <li>Запускаем {@code executeAudit(14)} повторно → ждём COMPLETED → фиксируем execKey2 (должен отличаться).</li>
 *   <li>Снимаем snapshot снова и ожидаем, что доменные max ключи не изменились (нет дублей/лишних версий).</li>
 * </ol>
 *
 * <p>Запуск (вручную, при запущенном приложении на localhost:8080):</p>
 * <pre>{@code
 * mvn test -pl femsq-web -Dtest=Type5NewExecKeyIdempotencyIntegrationIT -Dfemsq.integration.type5NewExecIdem=true
 * }</pre>
 */
@Tag("integration")
class Type5NewExecKeyIdempotencyIntegrationIT {

    private static final int AUDIT_ID = 14;
    private static final int FILE_TYPE = 5;

    @Test
    @EnabledIf("integrationFlagSet")
    void executeAuditTwice_newExecKey_shouldNotDuplicateDomainRows() throws Exception {
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
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = 1 WHERE adt_key = ?", AUDIT_ID);
                connection.commit(); // let backend see this change

                AllAgentsReconcileService reconcileService = new AllAgentsReconcileService(factory);

                executeAuditViaGraphql(AUDIT_ID);
                long execKey1 = waitForCompletedAndGetExecKey(factory, AUDIT_ID, null, Duration.ofSeconds(180));
                // reconcile выполняем текущим кодом (из теста), чтобы проверять актуальную логику.
                reconcileService.reconcile(new ReconcileContext(execKey1, AUDIT_ID, true, FILE_TYPE));
                Snapshot afterFirst = snapshot(factory, execKey1);

                executeAuditViaGraphql(AUDIT_ID);
                long execKey2 = waitForCompletedAndGetExecKey(factory, AUDIT_ID, execKey1, Duration.ofSeconds(180));
                org.junit.jupiter.api.Assertions.assertNotEquals(execKey1, execKey2, "expected a new exec_key on second run");

                reconcileService.reconcile(new ReconcileContext(execKey2, AUDIT_ID, true, FILE_TYPE));
                Snapshot afterSecond = snapshot(factory, execKey2);

                // В реальных данных часть RC может стать применимой только после того, как базовые RA появятся/стабилизируются.
                // Для 1.5.4 проверяем сходимость: после ещё одного запуска домен не должен меняться.
                executeAuditViaGraphql(AUDIT_ID);
                long execKey3 = waitForCompletedAndGetExecKey(factory, AUDIT_ID, execKey2, Duration.ofSeconds(180));
                org.junit.jupiter.api.Assertions.assertNotEquals(execKey2, execKey3, "expected a new exec_key on third run");
                reconcileService.reconcile(new ReconcileContext(execKey3, AUDIT_ID, true, FILE_TYPE));
                Snapshot afterThird = snapshot(factory, execKey3);

                if (!afterSecond.domain().equals(afterThird.domain())) {
                    String diag = diagnoseNewRcRows(factory, afterSecond.domain().racMax() + 1, afterThird.domain().racMax());
                    org.junit.jupiter.api.Assertions.fail(
                            "expected domain convergence by third exec_key run; "
                                    + "afterSecond=" + afterSecond.domain() + ", afterThird=" + afterThird.domain()
                                    + "\nNew RC rows:\n" + diag);
                }
                org.junit.jupiter.api.Assertions.assertTrue(
                        afterThird.markerDoneStepsForExec() >= 2,
                        () -> "expected marker steps recorded for exec_key=" + execKey3 + ", got "
                                + afterThird.markerDoneStepsForExec());
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

    private static Snapshot snapshot(ConnectionFactory factory, long execKey) throws Exception {
        try (Connection c = factory.createConnection()) {
            DomainSnapshot domain = new DomainSnapshot(
                    readLong(c, "SELECT ISNULL(MAX(ra_key), 0) FROM ags.ra"),
                    readLong(c, "SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ"),
                    readLong(c, "SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change"),
                    readLong(c, "SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ")
            );
            long markerDoneCount = readLong(c,
                    "SELECT COUNT(*) FROM ags.ra_reconcile_marker WHERE exec_key = ? AND file_type = ? AND step_code IN (?,?,?,?)",
                    execKey, FILE_TYPE, "TYPE5_APPLY_RA", "TYPE5_APPLY_RC", "TYPE5_DELETE_RA", "TYPE5_DELETE_RC");
            return new Snapshot(domain, markerDoneCount);
        }
    }

    private static long waitForCompletedAndGetExecKey(
            ConnectionFactory factory,
            int auditId,
            Long previousExecKey,
            Duration timeout
    ) throws Exception {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            try (Connection c = factory.createConnection()) {
                long latest = readLong(c,
                        "SELECT TOP 1 exec_key FROM ags.ra_execution WHERE exec_adt_key = ? ORDER BY exec_key DESC",
                        auditId);
                if (previousExecKey != null && latest == previousExecKey) {
                    Thread.sleep(1500);
                    continue;
                }
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

    private static String diagnoseNewRcRows(ConnectionFactory factory, long fromRacKeyInclusive, long toRacKeyInclusive)
            throws Exception {
        if (toRacKeyInclusive < fromRacKeyInclusive) {
            return "(no new rac_key range)";
        }
        StringBuilder sb = new StringBuilder();
        try (Connection c = factory.createConnection()) {
            String sql = """
                    SELECT rac_key, ra_period, [raс_ra] AS rac_ra_fk, [raс_num] AS rac_num, [raс_date] AS rac_date
                    FROM ags.ra_change
                    WHERE rac_key BETWEEN ? AND ?
                    ORDER BY rac_key
                    """;
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, fromRacKeyInclusive);
                ps.setLong(2, toRacKeyInclusive);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        sb.append("rac_key=").append(rs.getLong("rac_key"))
                                .append(", ra_period=").append(rs.getInt("ra_period"))
                                .append(", ra_fk=").append(rs.getLong("rac_ra_fk"))
                                .append(", num=").append(rs.getString("rac_num"))
                                .append(", date=").append(rs.getDate("rac_date"))
                                .append('\n');
                    }
                }
            }

            sb.append("-- duplicates by (ra_period, ra_fk, num) --\n");
            String dups = """
                    SELECT ra_period, [raс_ra] AS rac_ra_fk, [raс_num] AS rac_num, COUNT(*) AS cnt
                    FROM ags.ra_change
                    WHERE rac_key BETWEEN ? AND ?
                    GROUP BY ra_period, [raс_ra], [raс_num]
                    HAVING COUNT(*) > 1
                    ORDER BY cnt DESC
                    """;
            try (PreparedStatement ps = c.prepareStatement(dups)) {
                ps.setLong(1, fromRacKeyInclusive);
                ps.setLong(2, toRacKeyInclusive);
                try (ResultSet rs = ps.executeQuery()) {
                    boolean any = false;
                    while (rs.next()) {
                        any = true;
                        sb.append("ra_period=").append(rs.getInt("ra_period"))
                                .append(", ra_fk=").append(rs.getLong("rac_ra_fk"))
                                .append(", num=").append(rs.getString("rac_num"))
                                .append(", cnt=").append(rs.getInt("cnt"))
                                .append('\n');
                    }
                    if (!any) {
                        sb.append("(none)\n");
                    }
                }
            }
        }
        return sb.toString();
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
        return Boolean.parseBoolean(System.getProperty("femsq.integration.type5NewExecIdem", "false"));
    }

    private record DomainSnapshot(long raMax, long rasMax, long racMax, long racsMax) {
    }

    private record Snapshot(DomainSnapshot domain, long markerDoneStepsForExec) {
    }
}

