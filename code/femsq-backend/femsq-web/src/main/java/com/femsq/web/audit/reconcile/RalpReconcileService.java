package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.SQLException;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=3 (Ralp), каркас для последующей реализации.
 */
@Service
public class RalpReconcileService extends AbstractTransactionalReconcileService {

    private static final int TYPE_RALP = 3;

    public RalpReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_RALP;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context) throws SQLException {
        return ReconcileResult.skipped("type=3 reconcile is not implemented yet");
    }
}
