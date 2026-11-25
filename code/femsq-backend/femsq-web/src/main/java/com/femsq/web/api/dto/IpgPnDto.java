package com.femsq.web.api.dto;

import java.math.BigDecimal;

/**
 * DTO пункта ИП (+ код / стройка / агент из САК).
 */
public record IpgPnDto(
        Integer ipgpKey,
        Integer ipgpIpg,
        Integer ipgpNum,
        Integer ipgpCstAgPn,
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
        Integer ipgpSh,
        String ipgpShName
) {
}
