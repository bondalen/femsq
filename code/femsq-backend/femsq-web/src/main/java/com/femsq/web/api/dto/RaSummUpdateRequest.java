package com.femsq.web.api.dto;

import java.time.OffsetDateTime;

/**
 * Запрос обновления версии сумм.
 */
public record RaSummUpdateRequest(
        Integer rasRa,
        Double rasTotal,
        Double rasWork,
        Double rasEquip,
        Double rasOthers,
        OffsetDateTime rasDate
) {
}
