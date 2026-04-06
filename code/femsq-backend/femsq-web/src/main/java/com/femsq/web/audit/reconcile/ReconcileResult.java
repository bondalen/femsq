package com.femsq.web.audit.reconcile;

/**
 * Результат выполнения reconcile по одному типу файла.
 *
 * @param applied              признак применения reconcile
 * @param affectedRows         количество затронутых доменных строк
 * @param message              диагностическое сообщение
 * @param type5AuditCounters   структурированные счётчики для type=5; {@code null} для прочих типов
 */
public record ReconcileResult(
        boolean applied,
        int affectedRows,
        String message,
        Type5ReconcileAuditCounters type5AuditCounters
) {
    public static ReconcileResult skipped(String message) {
        return new ReconcileResult(false, 0, message, null);
    }

    public static ReconcileResult applied(int affectedRows, String message) {
        return new ReconcileResult(true, affectedRows, message, null);
    }

    public static ReconcileResult skipped(String message, Type5ReconcileAuditCounters type5AuditCounters) {
        return new ReconcileResult(false, 0, message, type5AuditCounters);
    }

    public static ReconcileResult applied(int affectedRows, String message, Type5ReconcileAuditCounters type5AuditCounters) {
        return new ReconcileResult(true, affectedRows, message, type5AuditCounters);
    }
}
