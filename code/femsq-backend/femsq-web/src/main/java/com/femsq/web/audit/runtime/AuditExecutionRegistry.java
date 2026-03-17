package com.femsq.web.audit.runtime;

import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * In-memory реестр статусов выполнения ревизий.
 *
 * <p>Служебная (инфраструктурная) информация: не хранится в БД.</p>
 */
@Component
public class AuditExecutionRegistry {

    private final ConcurrentHashMap<Long, AuditExecutionState> states = new ConcurrentHashMap<>();

    public Optional<AuditExecutionState> getState(long auditId) {
        return Optional.ofNullable(states.get(auditId));
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
    public boolean tryMarkRunning(long auditId) {
        final boolean[] started = {false};
        states.compute(auditId, (id, current) -> {
            if (current != null && current.status() == AuditRunStatus.RUNNING) {
                return current;
            }
            started[0] = true;
            return new AuditExecutionState(auditId, AuditRunStatus.RUNNING, Instant.now(), null, null);
        });
        return started[0];
    }

    public void markRunning(long auditId) {
        states.put(auditId, new AuditExecutionState(auditId, AuditRunStatus.RUNNING, Instant.now(), null, null));
    }

    public void markCompleted(long auditId) {
        states.compute(auditId, (id, current) -> new AuditExecutionState(
                auditId,
                AuditRunStatus.COMPLETED,
                current != null ? current.startedAt() : Instant.now(),
                Instant.now(),
                null
        ));
    }

    public void markFailed(long auditId, String errorMessage) {
        states.compute(auditId, (id, current) -> new AuditExecutionState(
                auditId,
                AuditRunStatus.FAILED,
                current != null ? current.startedAt() : Instant.now(),
                Instant.now(),
                errorMessage
        ));
    }
}
