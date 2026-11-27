package com.femsq.web.api.dto;

import java.math.BigDecimal;

/**
 * DTO заголовка UtPlP.
 */
public record IpgUtPlPDto(
        Integer iuplpKey,
        Integer iuplpPl,
        Integer iuplpIpgPn,
        BigDecimal iuplpLim,
        Integer iuplpSubAg
) {
}
