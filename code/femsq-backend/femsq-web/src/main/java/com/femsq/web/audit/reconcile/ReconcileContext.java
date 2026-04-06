package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.AuditExecutionContext;

/**
 * Входные параметры запуска reconcile.
 *
 * @param executionKey           ключ выполнения ревизии ({@code ra_execution.exec_key})
 * @param auditId                ключ ревизии ({@code ra_a.adt_key})
 * @param addRa                  флаг применения reconcile в доменные таблицы
 * @param fileType               тип файла ({@code af_type})
 * @param auditExecutionContext  контекст аудита для структурированного лога; {@code null} в тестах без UI-журнала
 */
public record ReconcileContext(
        long executionKey,
        long auditId,
        boolean addRa,
        int fileType,
        AuditExecutionContext auditExecutionContext
) {
    /**
     * Вызов без привязки к журналу аудита (интеграционные тесты, утилиты).
     */
    public ReconcileContext(long executionKey, long auditId, boolean addRa, int fileType) {
        this(executionKey, auditId, addRa, fileType, null);
    }
}
