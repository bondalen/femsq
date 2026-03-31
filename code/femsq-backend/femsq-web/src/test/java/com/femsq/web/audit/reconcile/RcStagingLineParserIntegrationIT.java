package com.femsq.web.audit.reconcile;

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
 * Полный прогон парсера по строкам «ОА изм» с реальным годом отчёта 2025–2026 в БД.
 * Запуск: {@code mvn test -pl femsq-web -Dtest=RcStagingLineParserIntegrationIT -Dfemsq.integration.rcParser=true}
 */
@Tag("integration")
class RcStagingLineParserIntegrationIT {

    @Test
    @EnabledIf("integrationFlagSet")
    void parseAllStagingOizmRowsForReportYears2025and2026() throws Exception {
        DatabaseConfigurationService cfgService =
                new DatabaseConfigurationService(new ConfigurationFileManager(), new ConfigurationValidator());
        try (ConnectionFactory factory = new ConnectionFactory(cfgService);
                Connection connection = factory.createConnection()) {

            /* DISTINCT: одна проверка на шаблон текста; иначе дубликаты строк Excel раздувают fail без новой информации. */
            String sql = """
                    SELECT DISTINCT rainRaNum
                    FROM ags.ra_stg_ra
                    WHERE LTRIM(RTRIM(ISNULL(rainSign, ''))) = N'ОА изм'
                      AND rainRaDate IS NOT NULL
                      AND YEAR(rainRaDate) IN (2025, 2026)
                    """;
            int ok = 0;
            int fail = 0;
            try (PreparedStatement ps = connection.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String num = rs.getString(1);
                    if (RcStagingLineParser.parse(num).isPresent()) {
                        ok++;
                    } else {
                        fail++;
                    }
                }
            }
            double rate = fail * 100.0 / Math.max(1, ok + fail);
            System.out.printf(
                    "[RcStagingLineParser IT] distinctRainRaNum=%d ok=%d fail=%d failRate=%.2f%%%n",
                    ok + fail, ok, fail, rate);
            final int okFinal = ok;
            final int failFinal = fail;
            org.junit.jupiter.api.Assertions.assertTrue(
                    okFinal >= 40,
                    "expected majority of distinct patterns to parse (check DB connectivity / data)");
            org.junit.jupiter.api.Assertions.assertTrue(
                    rate <= 25.0,
                    () -> String.format(
                            "parse failure rate too high: %.2f%% (ok=%d fail=%d). "
                                    + "Typical cause: rainRaNum without extractable date, or parser drift from VBA.",
                            rate, okFinal, failFinal));
        }
    }

    @SuppressWarnings("unused")
    static boolean integrationFlagSet() {
        return Boolean.parseBoolean(System.getProperty("femsq.integration.rcParser", "false"));
    }
}
