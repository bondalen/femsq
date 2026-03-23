package com.femsq.web.audit.stage2;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
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
                connection.commit();
                return new ResolutionResult(resolvedCst, resolvedOg, resolvedSmSender, computedStatus);
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException("Failed to resolve FK/derived for type 3, exec_key=" + executionKey, exception);
        }
    }

    private int executeUpdate(Connection connection, String sql, long executionKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            return statement.executeUpdate();
        }
    }

    /**
     * Результат Stage 2a/2b по type 3.
     */
    public record ResolutionResult(
            int resolvedCstAgPn,
            int resolvedOgSender,
            int resolvedSmSender,
            int computedStatus
    ) {
    }
}
