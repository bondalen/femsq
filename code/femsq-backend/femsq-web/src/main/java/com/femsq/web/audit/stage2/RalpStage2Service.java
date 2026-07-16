package com.femsq.web.audit.stage2;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Stage 2a/2b сервис для type 3 ({@code ra_stg_ralp}, {@code ra_stg_ralp_sm}).
 */
@Service
public class RalpStage2Service {

    private final ConnectionFactory connectionFactory;

    public RalpStage2Service(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    /**
     * Выполняет FK-resolution и вычисление derived-поля статуса по одной сессии выполнения.
     */
    public ResolutionResult resolveForExecution(long executionKey) {
        String sqlCstAgPn = """
                UPDATE stg
                SET stg.ralprtCstAgPn = cst.cstapKey
                FROM ags.ra_stg_ralp stg
                INNER JOIN ags.cstAgPn cst
                    ON LTRIM(RTRIM(ISNULL(stg.ralprtCstCodeStr, N''))) = LTRIM(RTRIM(ISNULL(cst.cstapIpgPnN, N'')))
                WHERE stg.ralprt_exec_key = ?
                  AND stg.ralprtCstAgPn IS NULL
                """;

        String sqlOgSender = """
                UPDATE stg
                SET stg.ralprtOgSender = og.onfKey
                FROM ags.ra_stg_ralp stg
                INNER JOIN ags.ogNmF og
                    ON LTRIM(RTRIM(ISNULL(stg.ralprtOgSenderStr, N''))) = LTRIM(RTRIM(ISNULL(og.onfName, N'')))
                   AND (
                        LTRIM(RTRIM(ISNULL(stg.ralprtOgBranchStr, N''))) = LTRIM(RTRIM(ISNULL(og.onfNameExt, N'')))
                        OR LTRIM(RTRIM(ISNULL(stg.ralprtOgBranchStr, N''))) = N''
                   )
                WHERE stg.ralprt_exec_key = ?
                  AND stg.ralprtOgSender IS NULL
                """;

        String sqlSenderSm = """
                UPDATE sm
                SET sm.ralprsSender = og.onfKey
                FROM ags.ra_stg_ralp_sm sm
                INNER JOIN ags.ogNmF og
                    ON LTRIM(RTRIM(ISNULL(sm.ralprsSenderStr, N''))) = LTRIM(RTRIM(ISNULL(og.onfName, N'')))
                WHERE sm.ralprs_exec_key = ?
                  AND sm.ralprsSender IS NULL
                """;

        String sqlStatus = """
                UPDATE stg
                SET stg.ralprtStatus =
                    CASE
                        WHEN ISNULL(stg.ralprtReturnedFlg, 0) <> 0 THEN 3
                        WHEN ISNULL(stg.ralprtSentToBook, 0) <> 0 THEN 2
                        WHEN ISNULL(stg.ralprtPresented, 0) <> 0 THEN 1
                        ELSE 0
                    END
                FROM ags.ra_stg_ralp stg
                WHERE stg.ralprt_exec_key = ?
                """;

        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int resolvedCst = executeUpdate(connection, sqlCstAgPn, executionKey);
                int resolvedOg = executeUpdate(connection, sqlOgSender, executionKey);
                int resolvedSmSender = executeUpdate(connection, sqlSenderSm, executionKey);
                int computedStatus = executeUpdate(connection, sqlStatus, executionKey);
                UnresolvedStats stats = loadUnresolvedStats(connection, executionKey);
                connection.commit();
                return new ResolutionResult(
                        resolvedCst,
                        resolvedOg,
                        resolvedSmSender,
                        computedStatus,
                        stats.stagingRows(),
                        stats.unresolvedRows(),
                        stats.unresolvedCst(),
                        stats.unresolvedOg(),
                        stats.unresolvedDate()
                );
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException("Failed to resolve FK/derived for type 3, exec_key=" + executionKey, exception);
        }
    }

    /**
     * Загружает строки staging с незаполненным FK/датой после Stage 2 (для SUMMARY/VERBOSE логов).
     *
     * @param executionKey ключ выполнения ревизии
     * @return список аномалий, упорядоченный по Excel-строке
     */
    public List<RalpFkAnomalyRow> loadUnresolvedAnomalies(long executionKey) {
        try (Connection connection = connectionFactory.createConnection()) {
            return loadUnresolvedAnomalies(connection, executionKey);
        } catch (SQLException exception) {
            throw new AuditExcelException(
                    "Failed to load unresolved RALP FK anomalies, exec_key=" + executionKey,
                    exception
            );
        }
    }

    /**
     * То же, что {@link #loadUnresolvedAnomalies(long)}, но на уже открытом соединении.
     * Нужно при вызове из транзакции сверки — отдельное соединение даёт самоблокировку на staging.
     *
     * @param connection   соединение (например TX сверки)
     * @param executionKey ключ выполнения
     * @return список аномалий
     */
    public List<RalpFkAnomalyRow> loadUnresolvedAnomalies(Connection connection, long executionKey) {
        Objects.requireNonNull(connection, "connection");
        String sql = """
                SELECT ralprt_key, ralprtRow, ralprtNum, ralprtDate,
                       ralprtCstCodeStr, ralprtOgSenderStr, ralprtOgBranchStr,
                       ralprtCstAgPn, ralprtOgSender
                FROM ags.ra_stg_ralp
                WHERE ralprt_exec_key = ?
                  AND (ralprtCstAgPn IS NULL OR ralprtOgSender IS NULL OR ralprtDate IS NULL)
                ORDER BY CASE WHEN ralprtRow IS NULL THEN 1 ELSE 0 END,
                         ralprtRow,
                         ralprt_key
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            List<RalpFkAnomalyRow> rows = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapAnomalyRow(rs));
                }
            }
            return rows;
        } catch (SQLException exception) {
            throw new AuditExcelException(
                    "Failed to load unresolved RALP FK anomalies, exec_key=" + executionKey,
                    exception
            );
        }
    }

    private UnresolvedStats loadUnresolvedStats(Connection connection, long executionKey) throws SQLException {
        String sql = """
                SELECT
                    COUNT(*) AS staging_rows,
                    SUM(CASE WHEN ralprtCstAgPn IS NULL OR ralprtOgSender IS NULL OR ralprtDate IS NULL
                             THEN 1 ELSE 0 END) AS unresolved_rows,
                    SUM(CASE WHEN ralprtCstAgPn IS NULL THEN 1 ELSE 0 END) AS unresolved_cst,
                    SUM(CASE WHEN ralprtOgSender IS NULL THEN 1 ELSE 0 END) AS unresolved_og,
                    SUM(CASE WHEN ralprtDate IS NULL THEN 1 ELSE 0 END) AS unresolved_date
                FROM ags.ra_stg_ralp
                WHERE ralprt_exec_key = ?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return new UnresolvedStats(0, 0, 0, 0, 0);
                }
                return new UnresolvedStats(
                        rs.getInt("staging_rows"),
                        rs.getInt("unresolved_rows"),
                        rs.getInt("unresolved_cst"),
                        rs.getInt("unresolved_og"),
                        rs.getInt("unresolved_date")
                );
            }
        }
    }

    private static RalpFkAnomalyRow mapAnomalyRow(ResultSet rs) throws SQLException {
        Integer excelRow = (Integer) rs.getObject("ralprtRow");
        java.sql.Date sqlDate = rs.getDate("ralprtDate");
        LocalDate reportDate = sqlDate == null ? null : sqlDate.toLocalDate();
        Integer cstAgPn = (Integer) rs.getObject("ralprtCstAgPn");
        Integer ogSender = (Integer) rs.getObject("ralprtOgSender");
        return new RalpFkAnomalyRow(
                rs.getLong("ralprt_key"),
                excelRow,
                rs.getString("ralprtNum"),
                reportDate,
                rs.getString("ralprtCstCodeStr"),
                rs.getString("ralprtOgSenderStr"),
                rs.getString("ralprtOgBranchStr"),
                cstAgPn,
                ogSender
        );
    }

    private int executeUpdate(Connection connection, String sql, long executionKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            return executeUpdate(statement);
        }
    }

    private int executeUpdate(PreparedStatement statement) throws SQLException {
        return statement.executeUpdate();
    }

    private record UnresolvedStats(
            int stagingRows,
            int unresolvedRows,
            int unresolvedCst,
            int unresolvedOg,
            int unresolvedDate
    ) {
    }

    /**
     * Результат Stage 2a/2b по type 3, включая счётчики неразрешённых FK.
     */
    public record ResolutionResult(
            int resolvedCstAgPn,
            int resolvedOgSender,
            int resolvedSmSender,
            int computedStatus,
            int stagingRows,
            int unresolvedRows,
            int unresolvedCst,
            int unresolvedOg,
            int unresolvedDate
    ) {
    }
}
