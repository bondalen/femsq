package com.femsq.web.audit.runtime;

/**
 * Технический статус выполнения ревизии.
 *
 * Не хранится в БД и используется только для управления процессом выполнения,
 * polling на фронтенде и защиты от повторного запуска.
 */
public enum AuditRunStatus {
    IDLE,
    RUNNING,
    COMPLETED,
    FAILED
}
