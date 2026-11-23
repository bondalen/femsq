package com.femsq.database.model;

import java.time.LocalDate;
import java.util.Objects;

/**
 * Полная карточка ИП ({@code ags.ipg}), не lookup-строка.
 */
public record IpgFull(
        int ipgKey,
        int ipgOg,
        String ogName,
        String ipgNm,
        int ipgYy,
        Integer year,
        short ipgNum,
        LocalDate ipgStr,
        LocalDate ipgEnd,
        Integer ipgRepl,
        int ipgStRlSh,
        String stNetName,
        Integer ipgYyYear
) {
    public IpgFull {
        Objects.requireNonNull(ipgNm, "ipgNm");
        Objects.requireNonNull(ipgStr, "ipgStr");
    }
}
