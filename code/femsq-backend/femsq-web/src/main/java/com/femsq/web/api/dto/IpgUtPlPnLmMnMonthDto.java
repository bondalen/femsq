package com.femsq.web.api.dto;

import java.math.BigDecimal;

/**
 * DTO оси C месяца.
 */
public record IpgUtPlPnLmMnMonthDto(
        Integer plPnKey,
        Integer month,
        BigDecimal lim212,
        BigDecimal lim195,
        BigDecimal lim172,
        BigDecimal lim187,
        String aggCode
) {
}
