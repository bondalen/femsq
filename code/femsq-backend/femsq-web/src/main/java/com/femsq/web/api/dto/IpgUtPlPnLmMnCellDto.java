package com.femsq.web.api.dto;

import java.math.BigDecimal;

/**
 * DTO ячейки LmMn.
 */
public record IpgUtPlPnLmMnCellDto(
        Integer iuplpmKey,
        Integer iuplpmPlPn,
        Integer iuplpmStCost,
        Integer iuplpmMn,
        BigDecimal iuplpmLim
) {
}
