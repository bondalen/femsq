package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.SQLException;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=2 (CnPrDoc), каркас для последующей реализации.
 */
@Service
public class CnPrDocReconcileService extends AbstractTransactionalReconcileService {

    private static final int TYPE_CN_PRDOC = 2;

    public CnPrDocReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_CN_PRDOC;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context) throws SQLException {
        return ReconcileResult.skipped("type=2 reconcile is not implemented yet");
    }
}
