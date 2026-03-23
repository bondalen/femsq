package com.femsq.web.audit.reconcile;

/**
 * Результат выполнения reconcile по одному типу файла.
 *
 * @param applied      признак применения reconcile
 * @param affectedRows количество затронутых доменных строк
 * @param message      диагностическое сообщение
 */
public record ReconcileResult(
        boolean applied,
        int affectedRows,
        String message
) {
    public static ReconcileResult skipped(String message) {
        return new ReconcileResult(false, 0, message);
    }

    public static ReconcileResult applied(int affectedRows, String message) {
        return new ReconcileResult(true, affectedRows, message);
    }
}
