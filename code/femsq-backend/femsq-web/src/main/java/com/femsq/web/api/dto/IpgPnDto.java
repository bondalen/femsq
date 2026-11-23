package com.femsq.web.api.dto;

import java.math.BigDecimal;

/**
 * DTO пункта ИП.
 */
public record IpgPnDto(
        Integer ipgpKey,
        Integer ipgpIpg,
        Integer ipgpNum,
        Integer ipgpCstAgPn,
        String cstAgPnCode,
        BigDecimal ipgpSmTtl,
        BigDecimal ipgpSmWrk,
        BigDecimal ipgpSmEqu,
        BigDecimal ipgpSmOth,
        BigDecimal ipgpSmAgFee,
        BigDecimal ipgpCostAdjust,
        BigDecimal ipgpSmReserv,
        String ipgpTskCms,
        Integer ipgpSh,
        String ipgpShName
) {
}
