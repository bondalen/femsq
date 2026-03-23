package com.femsq.web.audit.stage2;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Stage 2a сервис для type 2 ({@code ra_stg_cn_prdoc}): заполнение FK-полей.
 */
@Service
public class CnPrDocStage2Service {

    private final ConnectionFactory connectionFactory;

    public CnPrDocStage2Service(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    /**
     * Выполняет FK-resolution для строк одной сессии выполнения ревизии.
     *
     * @param executionKey ключ выполнения ({@code ra_execution.exec_key})
     * @return количество обновлений по двум шагам
     */
    public ResolutionResult resolveForExecution(long executionKey) {
        String sqlTpOrd = """
                UPDATE stg
                SET stg.cnpdTpOrdKey = dict.pdtoKey
                FROM ags.ra_stg_cn_prdoc stg
                INNER JOIN ags.cn_PrDocT dict
                    ON LTRIM(RTRIM(ISNULL(stg.cnpdTpOrd, N''))) = LTRIM(RTRIM(ISNULL(dict.pdtoText, N'')))
                WHERE stg.cnpd_exec_key = ?
                  AND stg.cnpdTpOrdKey IS NULL
                """;

        String sqlCstAgPn = """
                UPDATE stg
                SET stg.pdpCstAgPnKey = cst.cstapKey
                FROM ags.ra_stg_cn_prdoc stg
                INNER JOIN ags.cstAgPn cst
                    ON LTRIM(RTRIM(ISNULL(stg.pdpCstAgPnStr, N''))) = LTRIM(RTRIM(ISNULL(cst.cstapIpgPnN, N'')))
                WHERE stg.cnpd_exec_key = ?
                  AND stg.pdpCstAgPnKey IS NULL
                """;

        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                int resolvedTpOrd = executeUpdate(connection, sqlTpOrd, executionKey);
                int resolvedCstAgPn = executeUpdate(connection, sqlCstAgPn, executionKey);
                connection.commit();
                return new ResolutionResult(resolvedTpOrd, resolvedCstAgPn);
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException("Failed to resolve FK for ra_stg_cn_prdoc, exec_key=" + executionKey, exception);
        }
    }

    private int executeUpdate(Connection connection, String sql, long executionKey) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            return statement.executeUpdate();
        }
    }

    /**
     * Результат Stage 2a FK-resolution.
     *
     * @param resolvedTpOrd     количество строк с заполненным {@code cnpdTpOrdKey}
     * @param resolvedCstAgPn   количество строк с заполненным {@code pdpCstAgPnKey}
     */
    public record ResolutionResult(int resolvedTpOrd, int resolvedCstAgPn) {
    }
}
