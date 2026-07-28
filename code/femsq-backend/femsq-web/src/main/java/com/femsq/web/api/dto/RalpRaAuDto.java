package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO строки {@code ags.ralpRaAu}.
 */
public record RalpRaAuDto(
        Integer ralpraKey,
        Integer ralpraRa,
        Double ralpraCostAndVat,
        String ralpraArrived,
        LocalDate ralpraArrivedDate,
        String ralpraReturned,
        LocalDate ralpraReturnedDate,
        String ralpraSent,
        LocalDate ralpraSentDate,
        String ralpraNote,
        int ralpraStatus
) {
}
