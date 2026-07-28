package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO строки списка Access {@code ralpRaCst}.
 */
public record RalpRaCstListEntryDto(
        Integer cstKey,
        String ogaNm,
        String cstapIpgPnN,
        int ralprKey,
        String ralprNum,
        LocalDate ralprDate,
        Integer ralprCstAgPn,
        Integer ralprOgSender,
        String ogNm,
        int auCnt,
        boolean hasReturned
) {
}
