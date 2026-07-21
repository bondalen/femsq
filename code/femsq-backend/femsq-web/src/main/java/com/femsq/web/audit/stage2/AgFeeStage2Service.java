package com.femsq.web.audit.stage2;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Stage 2a для type=6 ({@code ra_stg_agfee}): резолюция {@code oafptOafSenderKey} ({@code ogaKey})
 * и {@code oafptPnCstAgPnKey} ({@code cstapKey}) по логике VBA/T-SQL
 * {@code ogAgFeePnTestAgentKey} / {@code ogAgFeePnTestCstKey}.
 */
@Service
public class AgFeeStage2Service {

    private final ConnectionFactory connectionFactory;

    public AgFeeStage2Service(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    /**
     * Выполняет FK-resolution и собирает diagnostic AgentNo/CstNo для текущего {@code exec_key}.
     *
     * @param executionKey ключ выполнения ({@code ra_execution.exec_key})
     * @return результат резолюции со счётчиками и списками аномалий
     */
    public ResolutionResult resolveForExecution(long executionKey) {
        // Порт ogAgFeePnTestAgentKey: (sender, LEFT(cst,3)) → ровно один ogaKey.
        // JOIN на staging дополнительно по коду стройки (в legacy SP join был только по имени —
        // при двух кодах одного агента это неоднозначно; здесь join ужесточён намеренно).
        String sqlAgentKey = """
                UPDATE t
                SET t.oafptOafSenderKey = y.ogaKey
                FROM ags.ra_stg_agfee t
                INNER JOIN (
                    SELECT x.oafptOafSender, x.ogAgCode, o.ogaKey
                    FROM (
                        SELECT z.oafptOafSender, z.ogAgCode, COUNT(o.ogaKey) AS keyCount
                        FROM (
                            SELECT y.oafptOafSender, y.ogAgCode
                            FROM (
                                SELECT
                                    LTRIM(RTRIM(ISNULL(t.oafptOafSender, N''))) AS oafptOafSender,
                                    LEFT(LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))), 3) AS ogAgCode
                                FROM ags.ra_stg_agfee t
                                WHERE t.oafpt_exec_key = ?
                            ) AS y
                            GROUP BY y.oafptOafSender, y.ogAgCode
                        ) AS z
                        LEFT JOIN ags.ogNmF_allVariantsAg o
                            ON z.oafptOafSender = o.ogNm
                           AND z.ogAgCode = o.ogaCode
                        GROUP BY z.oafptOafSender, z.ogAgCode
                        HAVING COUNT(o.ogaKey) = 1
                    ) AS x
                    INNER JOIN ags.ogNmF_allVariantsAg o
                        ON x.oafptOafSender = o.ogNm
                       AND x.ogAgCode = o.ogaCode
                ) AS y
                    ON LTRIM(RTRIM(ISNULL(t.oafptOafSender, N''))) = y.oafptOafSender
                   AND LEFT(LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))), 3) = y.ogAgCode
                WHERE t.oafpt_exec_key = ?
                  AND t.oafptOafSenderKey IS NULL
                """;

        String sqlCstKey = """
                UPDATE t
                SET t.oafptPnCstAgPnKey = p.cstapKey
                FROM ags.ra_stg_agfee t
                INNER JOIN ags.cstAgPn p
                    ON LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))) = LTRIM(RTRIM(ISNULL(p.cstapIpgPnN, N'')))
                WHERE t.oafpt_exec_key = ?
                  AND t.oafptPnCstAgPnKey IS NULL
                """;

        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int resolvedAgents = executeUpdate(connection, sqlAgentKey, executionKey, executionKey);
                int resolvedCst = executeUpdate(connection, sqlCstKey, executionKey);
                List<AgFeeAgentAnomaly> agentAnomalies = loadAgentAnomalies(connection, executionKey);
                List<AgFeeCstAnomaly> cstAnomalies = loadCstAnomalies(connection, executionKey);
                Stats stats = loadStats(connection, executionKey);
                connection.commit();
                return new ResolutionResult(
                        resolvedAgents,
                        resolvedCst,
                        stats.stagingRows(),
                        stats.withSenderKey(),
                        stats.withCstKey(),
                        agentAnomalies,
                        cstAnomalies
                );
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException(
                    "Failed to resolve FK for ra_stg_agfee, exec_key=" + executionKey,
                    exception
            );
        }
    }

    private List<AgFeeAgentAnomaly> loadAgentAnomalies(Connection connection, long executionKey)
            throws SQLException {
        // Порт ogAgFeePnTestAgentNo: HAVING COUNT(ogaKey) <> 1
        String sql = """
                SELECT z.oafptOafSender, COUNT(o.ogaKey) AS keyCount
                FROM (
                    SELECT y.oafptOafSender, y.ogAgCode
                    FROM (
                        SELECT
                            LTRIM(RTRIM(ISNULL(t.oafptOafSender, N''))) AS oafptOafSender,
                            LEFT(LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))), 3) AS ogAgCode
                        FROM ags.ra_stg_agfee t
                        WHERE t.oafpt_exec_key = ?
                    ) AS y
                    GROUP BY y.oafptOafSender, y.ogAgCode
                ) AS z
                LEFT JOIN ags.ogNmF_allVariantsAg o
                    ON z.oafptOafSender = o.ogNm
                   AND z.ogAgCode = o.ogaCode
                GROUP BY z.oafptOafSender
                HAVING COUNT(o.ogaKey) <> 1
                ORDER BY z.oafptOafSender
                """;
        List<AgFeeAgentAnomaly> result = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(new AgFeeAgentAnomaly(rs.getString(1), rs.getInt(2)));
                }
            }
        }
        return result;
    }

    private List<AgFeeCstAnomaly> loadCstAnomalies(Connection connection, long executionKey)
            throws SQLException {
        // Порт ogAgFeePnTestCstNo: стройка из источника не найдена в cstAgPn.
        // Группируем в Java: один код стройки → список Excel-строк (oafptRow).
        String sql = """
                SELECT
                    LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))) AS cstCode,
                    t.oafptRow AS excelRow
                FROM ags.ra_stg_agfee t
                WHERE t.oafpt_exec_key = ?
                  AND LTRIM(RTRIM(ISNULL(t.oafptPnCstAgPn, N''))) <> N''
                  AND t.oafptPnCstAgPnKey IS NULL
                ORDER BY cstCode, excelRow
                """;
        java.util.LinkedHashMap<String, java.util.TreeSet<Integer>> rowsByCode = new java.util.LinkedHashMap<>();
        java.util.Map<String, Integer> countByCode = new java.util.HashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    String cstCode = rs.getString("cstCode");
                    if (cstCode == null || cstCode.isBlank()) {
                        continue;
                    }
                    countByCode.merge(cstCode, 1, Integer::sum);
                    int excelRow = rs.getInt("excelRow");
                    if (!rs.wasNull() && excelRow > 0) {
                        rowsByCode.computeIfAbsent(cstCode, k -> new java.util.TreeSet<>()).add(excelRow);
                    } else {
                        rowsByCode.computeIfAbsent(cstCode, k -> new java.util.TreeSet<>());
                    }
                }
            }
        }
        List<AgFeeCstAnomaly> result = new ArrayList<>(rowsByCode.size());
        for (var entry : rowsByCode.entrySet()) {
            String code = entry.getKey();
            result.add(new AgFeeCstAnomaly(
                    code,
                    List.copyOf(entry.getValue()),
                    countByCode.getOrDefault(code, entry.getValue().size())
            ));
        }
        return result;
    }

    private Stats loadStats(Connection connection, long executionKey) throws SQLException {
        String sql = """
                SELECT
                    COUNT(*) AS staging_rows,
                    SUM(CASE WHEN oafptOafSenderKey IS NOT NULL THEN 1 ELSE 0 END) AS with_sender,
                    SUM(CASE WHEN oafptPnCstAgPnKey IS NOT NULL THEN 1 ELSE 0 END) AS with_cst
                FROM ags.ra_stg_agfee
                WHERE oafpt_exec_key = ?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return new Stats(0, 0, 0);
                }
                return new Stats(rs.getInt(1), rs.getInt(2), rs.getInt(3));
            }
        }
    }

    private int executeUpdate(Connection connection, String sql, long... params) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                statement.setLong(i + 1, params[i]);
            }
            return statement.executeUpdate();
        }
    }

    private record Stats(int stagingRows, int withSenderKey, int withCstKey) {
    }

    /**
     * Результат Stage 2a type=6.
     *
     * @param resolvedAgents   число строк, получивших {@code oafptOafSenderKey} в этом прогоне
     * @param resolvedCst      число строк, получивших {@code oafptPnCstAgPnKey} в этом прогоне
     * @param stagingRows      всего строк staging по {@code exec_key}
     * @param rowsWithSenderKey строк с заполненным ключом агента
     * @param rowsWithCstKey   строк с заполненным ключом стройки
     * @param agentAnomalies   diagnostic AgentNo (HAVING keyCount &lt;&gt; 1)
     * @param cstAnomalies     diagnostic CstNo (стройка не найдена)
     */
    public record ResolutionResult(
            int resolvedAgents,
            int resolvedCst,
            int stagingRows,
            int rowsWithSenderKey,
            int rowsWithCstKey,
            List<AgFeeAgentAnomaly> agentAnomalies,
            List<AgFeeCstAnomaly> cstAnomalies
    ) {
    }
}
