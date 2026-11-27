package com.femsq.database.model;

/**
 * Имя узла структуры затрат ({@code ags.stCostNm}).
 */
public record StCostNm(
        int stcnKey,
        int stcnCost,
        String stcnNm
) {
}
