package com.femsq.web.api.dto;

import java.time.OffsetDateTime;

/**
 * Запрос создания версии сумм.
 */
public record RaSummCreateRequest(
        Integer rasRa,
        Double rasTotal,
        Double rasWork,
        Double rasEquip,
        Double rasOthers,
        OffsetDateTime rasDate
) {
}
