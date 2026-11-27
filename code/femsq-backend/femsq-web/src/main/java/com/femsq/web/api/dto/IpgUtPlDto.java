package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO плана агента ({@code ipgUtPl}).
 */
public record IpgUtPlDto(
        Integer iuplKey,
        String iuplNm,
        LocalDate iuplDate,
        Integer iuplAg,
        Integer iuplIpg
) {
}
