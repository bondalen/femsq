package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.SQLException;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=6 (AgFee2306), каркас для последующей реализации.
 */
@Service
public class AgFee2306ReconcileService extends AbstractTransactionalReconcileService {

    private static final int TYPE_AGFEE_2306 = 6;

    public AgFee2306ReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_AGFEE_2306;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context) throws SQLException {
        return ReconcileResult.skipped("type=6 reconcile is not implemented yet");
    }
}
