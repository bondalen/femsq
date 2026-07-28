package com.femsq.web.api.dto;

import java.time.OffsetDateTime;

/**
 * DTO сумм {@code ags.ra_summ}.
 */
public record RaSummDto(
        Integer rasKey,
        Integer rasRa,
        Double rasTotal,
        Double rasWork,
        Double rasEquip,
        Double rasOthers,
        OffsetDateTime rasDate
) {
}
