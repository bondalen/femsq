package com.femsq.web.api.dto;

/**
 * DTO имени узла затрат ({@code ags.stCostNm}).
 */
public record StCostNmDto(
        int stcnKey,
        int stcKey,
        String name
) {
}
