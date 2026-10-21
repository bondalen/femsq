package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * GraphQL input краткого отчёта по своду (**1.1.1.0.3.2**).
 *
 * @param svodPath путь к файлу общего свода
 * @param asOf дата отчёта (L6)
 */
public record PrepareSudzBriefReportInput(
        String svodPath,
        LocalDate asOf
) {
}
