package com.femsq.web.audit.reconcile;

import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Reconcile для type=5 (AllAgents), каркас для последующей реализации.
 */
@Service
public class AllAgentsReconcileService extends AbstractTransactionalReconcileService {

    private static final Logger log = Logger.getLogger(AllAgentsReconcileService.class.getName());
    private static final int TYPE_ALL_AGENTS = 5;

    public AllAgentsReconcileService(ConnectionFactory connectionFactory) {
        super(connectionFactory);
    }

    @Override
    public boolean supports(int fileType) {
        return fileType == TYPE_ALL_AGENTS;
    }

    @Override
    protected ReconcileResult reconcileInTransaction(Connection connection, ReconcileContext context) throws SQLException {
        List<StagingRaRow> stagingRowsData = loadStagingRows(connection, context.executionKey());
        int stagingRows = stagingRowsData.size();
        int validationErrors = validateRequiredFields(stagingRowsData);
        int inserted = 0;
        int updated = 0;
        int skipped = Math.max(stagingRows - validationErrors, 0);
        int errors = validationErrors;

        String counters = formatCounters(stagingRows, inserted, updated, skipped, errors);
        log.info(() -> "[Reconcile][type=5] execKey=" + context.executionKey() + ", " + counters);
        return ReconcileResult.skipped("type=5 skeleton; " + counters);
    }

    private List<StagingRaRow> loadStagingRows(Connection connection, long executionKey) throws SQLException {
        String sql = """
                SELECT rain_key, rainRaNum
                FROM ags.ra_stg_ra
                WHERE rain_exec_key = ?
                ORDER BY rain_key
                """;
        List<StagingRaRow> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, executionKey);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(new StagingRaRow(
                            resultSet.getLong("rain_key"),
                            resultSet.getString("rainRaNum")
                    ));
                }
                return rows;
            }
        }
    }

    private int validateRequiredFields(List<StagingRaRow> rows) {
        int errors = 0;
        for (StagingRaRow row : rows) {
            if (trimToNull(row.raNum()) == null) {
                errors++;
            }
        }
        return errors;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String formatCounters(int stagingRows, int inserted, int updated, int skipped, int errors) {
        return "stagingRows=" + stagingRows
                + ", inserted=" + inserted
                + ", updated=" + updated
                + ", skipped=" + skipped
                + ", errors=" + errors;
    }

    /**
     * Минимальный срез staging-строки для начального reconcile-каркаса.
     */
    private record StagingRaRow(long key, String raNum) {
    }
}
