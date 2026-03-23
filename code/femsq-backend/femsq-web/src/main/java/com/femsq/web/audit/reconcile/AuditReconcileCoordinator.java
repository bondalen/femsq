package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditFile;
import com.femsq.web.audit.AuditLogEntry;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Координатор reconcile с единым форматом логирования шагов.
 */
@Service
public class AuditReconcileCoordinator {

    private final List<AuditReconcileService> reconcileServices;

    public AuditReconcileCoordinator(List<AuditReconcileService> reconcileServices) {
        this.reconcileServices = Objects.requireNonNull(reconcileServices, "reconcileServices");
    }

    public ReconcileResult run(AuditExecutionContext context, AuditFile file) {
        if (!Boolean.TRUE.equals(context.getAddRa())) {
            ReconcileResult skipped = ReconcileResult.skipped("addRa=false");
            appendResult(context, file, skipped);
            return skipped;
        }
        Long executionKey = context.getExecutionKey();
        if (executionKey == null) {
            ReconcileResult skipped = ReconcileResult.skipped("executionKey is null");
            appendResult(context, file, skipped);
            return skipped;
        }
        if (file.getType() == null) {
            ReconcileResult skipped = ReconcileResult.skipped("fileType is null");
            appendResult(context, file, skipped);
            return skipped;
        }

        AuditReconcileService service = reconcileServices.stream()
                .filter(candidate -> candidate.supports(file.getType()))
                .findFirst()
                .orElse(null);

        if (service == null) {
            ReconcileResult skipped = ReconcileResult.skipped("reconcile service not found for fileType=" + file.getType());
            appendResult(context, file, skipped);
            return skipped;
        }

        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "RECONCILE_START",
                "<P>Reconcile start: type=" + file.getType() + ", execKey=" + executionKey + "</P>",
                null
        ));

        ReconcileResult result = service.reconcile(new ReconcileContext(
                executionKey,
                context.getAuditId(),
                true,
                file.getType()
        ));
        appendResult(context, file, result);
        return result;
    }

    private void appendResult(AuditExecutionContext context, AuditFile file, ReconcileResult result) {
        String code = result.applied() ? "RECONCILE_DONE" : "RECONCILE_SKIPPED";
        context.appendEntry(new AuditLogEntry(
                Instant.now(),
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                code,
                "<P>Reconcile result: type=" + file.getType() + ", applied=" + result.applied()
                        + ", affectedRows=" + result.affectedRows()
                        + ", message=" + result.message() + "</P>",
                null
        ));
    }
}
