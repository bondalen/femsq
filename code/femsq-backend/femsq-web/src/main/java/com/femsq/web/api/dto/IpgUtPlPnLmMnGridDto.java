package com.femsq.web.api.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * DTO грида LmMn.
 */
public record IpgUtPlPnLmMnGridDto(
        Integer plPnKey,
        BigDecimal limYear,
        List<IpgUtPlPnLmMnMonthDto> months,
        List<IpgUtPlPnLmMnCellDto> cells,
        Boolean gAggOk
) {
}
