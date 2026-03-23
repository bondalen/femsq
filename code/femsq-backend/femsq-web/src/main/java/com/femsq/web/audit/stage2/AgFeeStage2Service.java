package com.femsq.web.audit.stage2;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Stage 2a сервис для type 6 ({@code ra_stg_agfee}): заполнение FK-поля {@code oafptOgKey}.
 */
@Service
public class AgFeeStage2Service {

    private final ConnectionFactory connectionFactory;

    public AgFeeStage2Service(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    /**
     * Выполняет FK-resolution по одной сессии выполнения.
     *
     * @param executionKey ключ выполнения ({@code ra_execution.exec_key})
     * @return количество обновлённых строк
     */
    public int resolveForExecution(long executionKey) {
        String sql = """
                UPDATE stg
                SET stg.oafptOgKey = og.ogKey
                FROM ags.ra_stg_agfee stg
                INNER JOIN ags.og og
                    ON LTRIM(RTRIM(ISNULL(stg.oafptOafSender, N''))) = LTRIM(RTRIM(ISNULL(og.ogNm, N'')))
                WHERE stg.oafpt_exec_key = ?
                  AND stg.oafptOgKey IS NULL
                """;

        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            return statement.executeUpdate();
        } catch (SQLException exception) {
            throw new AuditExcelException("Failed to resolve FK for ra_stg_agfee, exec_key=" + executionKey, exception);
        }
    }
}
