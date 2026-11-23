package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Пункт ИП ({@code ags.ipgPn}).
 */
public record IpgPn(
        int ipgpKey,
        int ipgpIpg,
        Integer ipgpNum,
        int ipgpCstAgPn,
        String cstAgPnCode,
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
