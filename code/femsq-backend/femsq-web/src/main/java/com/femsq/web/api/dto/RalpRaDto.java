package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO заголовка {@code ags.ralpRa}.
 */
public record RalpRaDto(
        Integer ralprKey,
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender,
        String ogNm,
        Integer ralprY,
        Integer ralprM
) {
}
