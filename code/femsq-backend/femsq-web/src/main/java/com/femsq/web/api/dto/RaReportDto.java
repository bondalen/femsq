package com.femsq.web.api.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;

/**
 * DTO отчёта {@code ags.ra}.
 */
public record RaReportDto(
        Integer raKey,
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
        OffsetDateTime raCreated,
        Integer raOrgSender,
        String raNote
) {
}
