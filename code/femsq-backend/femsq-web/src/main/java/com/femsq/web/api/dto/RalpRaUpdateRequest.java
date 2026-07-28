package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Запрос обновления {@code ags.ralpRa}.
 */
public record RalpRaUpdateRequest(
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender
) {
}
