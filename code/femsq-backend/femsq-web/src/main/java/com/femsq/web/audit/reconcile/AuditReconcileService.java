package com.femsq.web.audit.reconcile;

/**
 * Контракт reconcile (staging -> доменные таблицы) для конкретного типа файла.
 */
public interface AuditReconcileService {

    /**
     * Поддерживаемый тип файла.
     */
    boolean supports(int fileType);

    /**
     * Выполняет reconcile для конкретной сессии выполнения.
     */
    ReconcileResult reconcile(ReconcileContext context);
}
