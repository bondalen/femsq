package com.femsq.database.model;

import java.util.List;

/**
 * Результат сверки одной строки ПТСФ ({@code iiRowKind='S'}).
 */
public record ImpIpgReconcileRow(
        int rowId,
        int rowNo,
        String text,
        Integer stiKey,
        ImpIpgReconcileStatus status,
        List<Integer> candidateStiKeys,
        boolean pathMatched,
        boolean nameInPool,
        boolean closed) {
}
