package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет группу планов инвестиционной программы (таблица {@code ags.ipgUtPlGr}).
 */
public record InvestmentPlanGroup(
        Integer planGroupKey,
        String displayName
) {
    public InvestmentPlanGroup {
        Objects.requireNonNull(planGroupKey, "planGroupKey");
        Objects.requireNonNull(displayName, "displayName");
    }
}
