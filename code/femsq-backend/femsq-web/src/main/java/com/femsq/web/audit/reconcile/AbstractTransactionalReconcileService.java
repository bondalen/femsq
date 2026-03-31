package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.web.audit.excel.AuditExcelException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Objects;

/**
 * Базовый reconcile-сервис с транзакционными границами на уровень типа файла.
 */
public abstract class AbstractTransactionalReconcileService implements AuditReconcileService {

    private final ConnectionFactory connectionFactory;

    protected AbstractTransactionalReconcileService(ConnectionFactory connectionFactory) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public final ReconcileResult reconcile(ReconcileContext context) {
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                ReconcileResult result = reconcileInTransaction(connection, context);
                connection.commit();
                return result;
            } catch (SQLException exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException(buildSqlErrorMessage(context.fileType(), exception), exception);
        }
    }

    /**
     * Формирует диагностическое сообщение по цепочке SQL-исключений для лога и хранения в exec_error.
     */
    private String buildSqlErrorMessage(int fileType, SQLException exception) {
        StringBuilder message = new StringBuilder("Reconcile failed for fileType=")
                .append(fileType);
        SQLException current = exception;
        int index = 1;
        while (current != null) {
            if (index == 1) {
                message.append(": ");
            } else {
                message.append(" | cause#").append(index).append(": ");
            }
            message.append("sqlState=").append(current.getSQLState())
                    .append(", errorCode=").append(current.getErrorCode())
                    .append(", message=").append(current.getMessage());
            current = current.getNextException();
            index++;
        }
        return message.toString();
    }

    protected abstract ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context)
            throws SQLException;
}
