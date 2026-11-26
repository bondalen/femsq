package com.femsq.database.model;

import java.util.List;

/**
 * Итог сверки ПТСФ сессии со схемой {@code stNet}.
 * {@code logHtml} — накопительный лог «Ход загрузки» (C2 §3.5.4), nullable.
 */
public record ImpIpgReconcileResult(
        int loadKey,
        int stNetKey,
        int matched,
        int open,
        List<ImpIpgReconcileRow> rows,
        String logHtml) {

    /** Конструктор без лога ({@code logHtml = null}). */
    public ImpIpgReconcileResult(
            int loadKey, int stNetKey, int matched, int open, List<ImpIpgReconcileRow> rows) {
        this(loadKey, stNetKey, matched, open, rows, null);
    }
}
