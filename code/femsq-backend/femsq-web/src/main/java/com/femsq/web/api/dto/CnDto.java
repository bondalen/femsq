package com.femsq.web.api.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;

/**
 * DTO договора {@code ags.cn}.
 */
public record CnDto(
        Integer cnKey,
        String cnNumber,
        LocalDate cnDate,
        String cnNote,
        Integer cnMark,
        OffsetDateTime cnTimeOfEntry,
        String cnName
) {
}
