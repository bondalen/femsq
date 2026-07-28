package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Запрос обновления отчёта {@code ags.ra}.
 */
public record RaReportUpdateRequest(
        String raNum,
        LocalDate raDate,
        Integer raCac,
        String raType,
        String raWorkType,
        Integer raPeriod,
        String raArrived,
        LocalDate raArrivedDate,
        String raReturned,
        LocalDate raReturnedDate,
        String raSent,
        LocalDate raSentDate,
        String raNoteT,
        Integer raOrgSender,
        String raNote
) {
}
