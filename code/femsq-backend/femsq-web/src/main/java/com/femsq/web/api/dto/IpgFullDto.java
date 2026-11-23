package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO полной карточки ИП.
 */
public record IpgFullDto(
        Integer ipgKey,
        Integer ipgOg,
        String ogName,
        String ipgNm,
        Integer ipgYy,
        Integer year,
        Integer ipgNum,
        LocalDate ipgStr,
        LocalDate ipgEnd,
        Integer ipgRepl,
        Integer ipgStRlSh,
        String stNetName,
        Integer ipgYyYear
) {
}
