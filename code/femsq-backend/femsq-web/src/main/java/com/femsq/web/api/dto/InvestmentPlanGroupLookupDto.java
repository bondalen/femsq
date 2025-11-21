package com.femsq.web.api.dto;

/** DTO справочника групп планов инвестиционных программ. */
public record InvestmentPlanGroupLookupDto(
        Integer planGroupKey,
        String name
) {
}
