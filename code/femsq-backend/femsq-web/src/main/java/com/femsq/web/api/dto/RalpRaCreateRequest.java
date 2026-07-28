package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Запрос создания {@code ags.ralpRa}.
 */
public record RalpRaCreateRequest(
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender
) {
}
