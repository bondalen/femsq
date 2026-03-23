package com.femsq.web.audit.reconcile;

/**
 * Входные параметры запуска reconcile.
 *
 * @param executionKey ключ выполнения ревизии ({@code ra_execution.exec_key})
 * @param auditId      ключ ревизии ({@code ra_a.adt_key})
 * @param addRa        флаг применения reconcile в доменные таблицы
 * @param fileType     тип файла ({@code af_type})
 */
public record ReconcileContext(
        long executionKey,
        long auditId,
        boolean addRa,
        int fileType
) {
}
