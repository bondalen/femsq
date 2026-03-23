package com.femsq.web.audit.runtime;

import com.femsq.database.model.RaExecution;
import com.femsq.database.service.RaExecutionService;
import java.util.Optional;
import java.util.logging.Logger;
import org.springframework.stereotype.Component;

/**
 * Реестр статусов выполнения ревизий на базе таблицы {@code ags.ra_execution}.
 */
@Component
public class AuditExecutionRegistry {

    private static final Logger log = Logger.getLogger(AuditExecutionRegistry.class.getName());

    private final RaExecutionService raExecutionService;

    public AuditExecutionRegistry(RaExecutionService raExecutionService) {
        this.raExecutionService = raExecutionService;
    }

    public Optional<AuditExecutionState> getState(long auditId) {
        return raExecutionService.getLatestByAuditId((int) auditId).map(this::toState);
    }

    public AuditRunStatus getStatusOrIdle(long auditId) {
        return getState(auditId).map(AuditExecutionState::status).orElse(AuditRunStatus.IDLE);
    }

    public boolean isRunning(long auditId) {
        return getStatusOrIdle(auditId) == AuditRunStatus.RUNNING;
    }

    /**
     * Атомарно переводит ревизию в RUNNING, если она не RUNNING.
     *
     * @return {@code true}, если запуск разрешён (статус установлен RUNNING)
     */
    public boolean tryMarkRunning(long auditId, boolean addRa) {
        AuditRunStatus currentStatus = getStatusOrIdle(auditId);
        if (currentStatus == AuditRunStatus.RUNNING) {
            return false;
        }
        raExecutionService.startExecution((int) auditId, addRa);
        return true;
    }

    public void markRunning(long auditId, boolean addRa) {
        raExecutionService.startExecution((int) auditId, addRa);
    }

    public void markCompleted(long auditId) {
        raExecutionService.getLatestByAuditId((int) auditId)
                .filter(exec -> "RUNNING".equalsIgnoreCase(exec.execStatus()))
                .ifPresent(exec -> raExecutionService.completeExecution(exec.execKey()));
    }

    public void markFailed(long auditId, String errorMessage) {
        raExecutionService.getLatestByAuditId((int) auditId)
                .ifPresentOrElse(
                        exec -> raExecutionService.failExecution(exec.execKey(), errorMessage),
                        () -> log.warning("No execution record found to mark failed for auditId=" + auditId)
                );
    }

    private AuditExecutionState toState(RaExecution execution) {
        AuditRunStatus status;
        try {
            status = AuditRunStatus.valueOf(execution.execStatus().toUpperCase());
        } catch (Exception ignored) {
            status = AuditRunStatus.IDLE;
        }
        return new AuditExecutionState(
                execution.execAdtKey() != null ? execution.execAdtKey().longValue() : -1L,
                status,
                execution.execStarted() != null ? execution.execStarted().atZone(java.time.ZoneId.systemDefault()).toInstant() : null,
                execution.execFinished() != null ? execution.execFinished().atZone(java.time.ZoneId.systemDefault()).toInstant() : null,
                execution.execError()
        );
    }
}
