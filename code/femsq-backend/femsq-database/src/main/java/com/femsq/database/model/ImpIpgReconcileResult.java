package com.femsq.database.model;

import java.util.List;

/**
 * Итог сверки ПТСФ сессии со схемой {@code stNet}.
 */
public record ImpIpgReconcileResult(
        int loadKey,
        int stNetKey,
        int matched,
        int open,
        List<ImpIpgReconcileRow> rows) {
}
