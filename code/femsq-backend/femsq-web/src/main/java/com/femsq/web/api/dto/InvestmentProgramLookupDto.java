package com.femsq.web.api.dto;

/** DTO справочника инвестиционных программ. */
public record InvestmentProgramLookupDto(
        Integer ipgKey,
        String name
) {
}
