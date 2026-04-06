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
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.condition.EnabledIf;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;

/**
 * Acceptance 1.8.11.8: контрольные прогоны type=5 и проверка {@code ags.ra_a.adt_results}.
 *
 * <p>Проверяем устойчивые фрагменты HTML (русские тексты сообщений), а не внутренние {@code eventKey}
 * (в {@link com.femsq.web.audit.AuditExecutionContext#buildHtmlLog()} коды часто сворачиваются в badge «СОБЫТИЕ»).</p>
 *
 * <p>Запуск (вручную, БД + приложение на {@code http://127.0.0.1:8080}):</p>
 * <pre>{@code
 * mvn test -pl femsq-web -Dtest=Type5AcceptanceAdtResultsIntegrationIT -Dfemsq.integration.type5Acceptance=true
 * }</pre>
 *
 * <p>{@code adt_key} по умолчанию совпадает с прочими type=5 IT; при необходимости:
 * {@code -Dfemsq.integration.auditId=14}.</p>
 */
@Tag("integration")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@Execution(ExecutionMode.SAME_THREAD)
class Type5AcceptanceAdtResultsIntegrationIT {

    private static final int DEFAULT_AUDIT_ID = 14;

    private static int auditId() {
        String raw = System.getProperty("femsq.integration.auditId", String.valueOf(DEFAULT_AUDIT_ID));
        return Integer.parseInt(raw.trim());
    }

    @Test
    @Order(1)
    @EnabledIf("integrationFlagSet")
    void dryRun_addRaFalse_adtResults_containsExpectedPhases() throws Exception {
        int adtKey = auditId();
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory factory = new ConnectionFactory(cfgService);
                Connection connection = factory.createConnection()) {
            connection.setAutoCommit(false);
            int prevAddRa = readInt(connection, "SELECT CAST(adt_AddRA AS int) FROM ags.ra_a WHERE adt_key = ?", adtKey);
            try {
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = 0 WHERE adt_key = ?", adtKey);
                connection.commit();

                int baselineExecKey = readInt(connection,
                        "SELECT ISNULL(MAX(exec_key), 0) FROM ags.ra_execution WHERE exec_adt_key = ?", adtKey);
                executeAuditViaGraphql(adtKey);
                waitForNewCompleted(connection, adtKey, baselineExecKey, Duration.ofSeconds(180));

                String results = readString(connection,
                        "SELECT CAST(adt_results AS NVARCHAR(MAX)) FROM ags.ra_a WHERE adt_key = ?",
                        adtKey);
                assertAllSubstringsPresent(
                        results,
                        "Начало ревизии",
                        "ревизия завершена",
                        "диагностика",
                        "addRa=false",
                        "Всего строк отчётов",
                        "Всего строк изменений",
                        "Type5 match — RA:",
                        "Type5 apply — RA:",
                        "сухойПрогон=true");
            } finally {
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = ? WHERE adt_key = ?", prevAddRa, adtKey);
                connection.commit();
            }
        }
    }

    @Test
    @Order(2)
    @EnabledIf("integrationFlagSet")
    void apply_addRaTrue_adtResults_containsApplyModeAndStructuredStats() throws Exception {
        int adtKey = auditId();
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory factory = new ConnectionFactory(cfgService);
                Connection connection = factory.createConnection()) {
            connection.setAutoCommit(false);
            int prevAddRa = readInt(connection, "SELECT CAST(adt_AddRA AS int) FROM ags.ra_a WHERE adt_key = ?", adtKey);
            int baselineRaMax = readInt(connection, "SELECT ISNULL(MAX(ra_key), 0) FROM ags.ra");
            int baselineRasMax = readInt(connection, "SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ");
            int baselineRacMax = readInt(connection, "SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change");
            int baselineRacsMax = readInt(connection, "SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ");
            try {
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = 1 WHERE adt_key = ?", adtKey);
                connection.commit();

                int baselineExecKey = readInt(connection,
                        "SELECT ISNULL(MAX(exec_key), 0) FROM ags.ra_execution WHERE exec_adt_key = ?", adtKey);
                executeAuditViaGraphql(adtKey);
                waitForNewCompleted(connection, adtKey, baselineExecKey, Duration.ofSeconds(180));

                String results = readString(connection,
                        "SELECT CAST(adt_results AS NVARCHAR(MAX)) FROM ags.ra_a WHERE adt_key = ?",
                        adtKey);
                assertAllSubstringsPresent(
                        results,
                        "применение",
                        "addRa=true",
                        "Type5 match — RA:",
                        "Type5 apply — RA:",
                        "сухойПрогон=false");
                boolean rowLevelSignal = results.contains("Создана новая запись ags.ra")
                        || results.contains("Создана новая запись ags.ra_change")
                        || results.contains("RA суммы:")
                        || results.contains("RC суммы:")
                        || results.contains("расхождение сумм")
                        || results.contains("Лишняя запись в домене")
                        || results.contains("Лишнее изменение в домене")
                        || results.contains("отказ валидации");
                org.junit.jupiter.api.Assertions.assertTrue(
                        rowLevelSignal,
                        "adt_results: ожидался хотя бы один row-level маркер (NEW/суммы/validation/excess/mismatch) "
                                + "после apply — проверьте данные staging/домена для adt_key=" + adtKey);
            } finally {
                exec(connection, "DELETE FROM ags.ra_summ WHERE ras_key > ?", baselineRasMax);
                exec(connection, "DELETE FROM ags.ra WHERE ra_key > ?", baselineRaMax);
                exec(connection, "DELETE FROM ags.ra_change_summ WHERE [raсs_key] > ?", baselineRacsMax);
                exec(connection, "DELETE FROM ags.ra_change WHERE rac_key > ?", baselineRacMax);
                exec(connection, "UPDATE ags.ra_a SET adt_AddRA = ? WHERE adt_key = ?", prevAddRa, adtKey);
                connection.commit();
            }
        }
    }

    private static void assertAllSubstringsPresent(String haystack, String... needles) {
        List<String> missing = new ArrayList<>();
        for (String n : needles) {
            if (!haystack.contains(n)) {
                missing.add(n);
            }
        }
        if (!missing.isEmpty()) {
            org.junit.jupiter.api.Assertions.fail(
                    "adt_results не содержит ожидаемых фрагментов: " + missing);
        }
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

    /**
     * Waits for a NEW execution (exec_key &gt; baselineExecKey) to reach COMPLETED status.
     * This avoids reading a stale COMPLETED record from a previous run.
     */
    private static void waitForNewCompleted(Connection connection, int auditId, int baselineExecKey,
            Duration timeout) throws Exception {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            Thread.sleep(1500);
            Integer newExecKey = readIntOrNull(connection,
                    "SELECT TOP 1 exec_key FROM ags.ra_execution "
                            + "WHERE exec_adt_key = ? AND exec_key > ? ORDER BY exec_key DESC",
                    auditId, baselineExecKey);
            if (newExecKey == null) {
                continue;
            }
            String status = readString(connection,
                    "SELECT TOP 1 exec_status FROM ags.ra_execution WHERE exec_key = ?",
                    newExecKey);
            if ("COMPLETED".equalsIgnoreCase(status) || "FAILED".equalsIgnoreCase(status)) {
                org.junit.jupiter.api.Assertions.assertEquals(
                        "COMPLETED",
                        status,
                        "execution failed for exec_key=" + newExecKey);
                return;
            }
        }
        throw new IllegalStateException("Timeout waiting for new audit execution after exec_key=" + baselineExecKey);
    }

    private static void exec(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }

    private static Integer readIntOrNull(Connection connection, String sql, Object... params) throws Exception {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
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
        return Boolean.parseBoolean(System.getProperty("femsq.integration.type5Acceptance", "false"));
    }
}
