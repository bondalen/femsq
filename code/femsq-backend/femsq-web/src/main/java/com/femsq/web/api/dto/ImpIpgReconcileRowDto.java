package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO строки сверки ПТСФ.
 */
public record ImpIpgReconcileRowDto(
        int rowId,
        int rowNo,
        String text,
        Integer stiKey,
        String status,
        List<Integer> candidateStiKeys,
        boolean pathMatched,
        boolean nameInPool,
        boolean closed) {
}
