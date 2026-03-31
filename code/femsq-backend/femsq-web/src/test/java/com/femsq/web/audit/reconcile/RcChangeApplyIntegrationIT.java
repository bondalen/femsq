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
 * Интеграционный тест apply-ветки RC (1.3.2–1.3.3) на реальной БД.
 *
 * <p>Запуск (вручную): {@code mvn test -pl femsq-web -Dtest=RcChangeApplyIntegrationIT -Dfemsq.integration.rcApply=true}</p>
 *
 * <p>Сценарий:</p>
 * <ol>
 *   <li>Фиксируем baseline max ключей (`ags.ra`, `ags.ra_summ`, `ags.ra_change`, `ags.ra_change_summ`).</li>
 *   <li>Включаем {@code adt_AddRA=true} для {@code adt_key=14}.</li>
 *   <li>Запускаем {@code executeAudit(14)}: создаются RC NEW + суммы (1.3.2).</li>
 *   <li>Искажаем одну созданную строку `ags.ra_change` (меняем `ra_arrived`).</li>
 *   <li>Запускаем {@code executeAudit(14)} повторно: должна сработать ветка RC update (1.3.3).</li>
 *   <li>Откат: удаляем вставки по диапазонам ключей и возвращаем {@code adt_AddRA}.</li>
 * </ol>
 *
 * <p>Тест не предназначен для CI; он выполняется только при явном флаге.</p>
 */
@Tag("integration")
class RcChangeApplyIntegrationIT {

    private static final int AUDIT_ID = 14;

    @Test
    @EnabledIf("integrationFlagSet")
    void rcApply_createThenUpdate_shouldAffectAtLeastOneRow() throws Exception {
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

            try {
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = 1 WHERE adt_key = ?", AUDIT_ID);

                int exec1 = executeAuditViaGraphql(AUDIT_ID);
                waitForCompleted(connection, AUDIT_ID, exec1, Duration.ofSeconds(120));

                // Pick one inserted rac_key (rc create) and make it CHANGED for the next run.
                Integer insertedRacKey = readNullableInt(connection,
                        "SELECT TOP 1 rac_key FROM ags.ra_change WHERE rac_key > ? ORDER BY rac_key DESC",
                        baselineRacMax);
                org.junit.jupiter.api.Assertions.assertNotNull(insertedRacKey, "expected at least one RC create row");

                exec(connection,
                        "UPDATE ags.ra_change SET ra_arrived = N'__TEST_CHANGED__' WHERE rac_key = ?",
                        insertedRacKey);

                int exec2 = executeAuditViaGraphql(AUDIT_ID);
                waitForCompleted(connection, AUDIT_ID, exec2, Duration.ofSeconds(120));

                String results = readString(connection,
                        "SELECT CAST(adt_results AS NVARCHAR(MAX)) FROM ags.ra_a WHERE adt_key = ?",
                        AUDIT_ID);
                org.junit.jupiter.api.Assertions.assertTrue(
                        results.contains("rcChangesUpdated="),
                        "expected rcChangesUpdated counter in adt_results");

                int updated = extractCounter(results, "rcChangesUpdated=");
                org.junit.jupiter.api.Assertions.assertTrue(
                        updated >= 1,
                        () -> "expected rcChangesUpdated>=1, got " + updated);
            } finally {
                // Rollback all inserts we may have done. This must be safe even if test fails mid-run.
                exec(connection, "DELETE FROM ags.ra_summ WHERE ras_key > ?", baselineRasMax);
                exec(connection, "DELETE FROM ags.ra WHERE ra_key > ?", baselineRaMax);
                exec(connection, "DELETE FROM ags.ra_change_summ WHERE [raсs_key] > ?", baselineRacsMax);
                exec(connection, "DELETE FROM ags.ra_change WHERE rac_key > ?", baselineRacMax);
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = ? WHERE adt_key = ?", prevAddRa, AUDIT_ID);

                connection.commit();
            }
        }
    }

    private static int executeAuditViaGraphql(int auditId) throws Exception {
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
        return 0;
    }

    private static void waitForCompleted(Connection connection, int auditId, int execKeyHint, Duration timeout)
            throws Exception {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            int latest = readInt(connection,
                    "SELECT TOP 1 exec_key FROM ags.ra_execution WHERE exec_adt_key = ? ORDER BY exec_key DESC",
                    auditId);
            String status = readString(connection,
                    "SELECT TOP 1 exec_status FROM ags.ra_execution WHERE exec_key = ?",
                    latest);
            if ("COMPLETED".equalsIgnoreCase(status) || "FAILED".equalsIgnoreCase(status)) {
                org.junit.jupiter.api.Assertions.assertEquals("COMPLETED", status, "execution failed for exec_key=" + latest);
                return;
            }
            Thread.sleep(1500);
        }
        throw new IllegalStateException("Timeout waiting for audit " + auditId + " completion");
    }

    private static int extractCounter(String text, String key) {
        int pos = text.indexOf(key);
        if (pos < 0) {
            return -1;
        }
        int start = pos + key.length();
        int end = start;
        while (end < text.length() && Character.isDigit(text.charAt(end))) {
            end++;
        }
        return Integer.parseInt(text.substring(start, end));
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
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalStateException("No rows for query: " + sql);
                }
                return rs.getInt(1);
            }
        }
    }

    private static Integer readNullableInt(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                int value = rs.getInt(1);
                return rs.wasNull() ? null : value;
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
        return Boolean.parseBoolean(System.getProperty("femsq.integration.rcApply", "false"));
    }
}

