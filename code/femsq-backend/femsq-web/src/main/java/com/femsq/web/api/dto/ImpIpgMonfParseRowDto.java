package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO строки staging Monf parse (§6.5).
 */
public record ImpIpgMonfParseRowDto(
        int rowNo,
        String cstCode,
        String name,
        Double limYear,
        List<Double> quarters,
        List<Double> months,
        boolean skipped,
        String skipReason) {
}
