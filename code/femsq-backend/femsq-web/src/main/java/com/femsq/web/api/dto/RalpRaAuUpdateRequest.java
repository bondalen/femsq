package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Запрос обновления {@code ags.ralpRaAu}.
 */
public record RalpRaAuUpdateRequest(
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
