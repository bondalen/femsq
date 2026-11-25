package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Пункт ИП ({@code ags.ipgPn}) + отображаемые поля САК из {@code cstAgPn}.
 *
 * @param cstAgPnCode    код {@code cstapIpgPnN}
 * @param cstAgPnCstName наименование стройки {@code cstapCstName}
 * @param cstAgPnOgName  агент {@code cstapOgName}
 */
public record IpgPn(
        int ipgpKey,
        int ipgpIpg,
        Integer ipgpNum,
        int ipgpCstAgPn,
        String cstAgPnCode,
        String cstAgPnCstName,
        String cstAgPnOgName,
        BigDecimal ipgpSmTtl,
        BigDecimal ipgpSmWrk,
        BigDecimal ipgpSmEqu,
        BigDecimal ipgpSmOth,
        BigDecimal ipgpSmAgFee,
        BigDecimal ipgpCostAdjust,
        BigDecimal ipgpSmReserv,
        String ipgpTskCms,
        int ipgpSh,
        String ipgpShName
) {
}
