package com.femsq.web.audit.runtime;

import java.time.Instant;

/**
 * Текущее состояние выполнения ревизии в рамках одного процесса приложения.
 *
 * <p>Хранится в памяти JVM и сбрасывается при рестарте приложения.</p>
 */
public record AuditExecutionState(
        long auditId,
        AuditRunStatus status,
        Instant startedAt,
        Instant finishedAt,
        String errorMessage
) {
}
