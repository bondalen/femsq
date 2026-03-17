package com.femsq.web.api.dto;

/**
 * Результат запроса на запуск ревизии.
 *
 * @param started         {@code true}, если запуск инициирован
 * @param alreadyRunning  {@code true}, если ревизия уже выполняется
 * @param message         опциональное сообщение для отображения на фронтенде
 */
public record AuditExecutionResult(
        boolean started,
        boolean alreadyRunning,
        String message
) {
}

