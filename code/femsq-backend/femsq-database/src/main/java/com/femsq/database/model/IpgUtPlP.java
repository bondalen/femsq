package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Заголовок уточнённого плана по пункту ({@code ags.ipgUtPlP}).
 *
 * @param iuplpKey   PK
 * @param iuplpPl    план агента ({@code ipgUtPl})
 * @param iuplpIpgPn пункт ({@code ipgPn})
 * @param iuplpLim   лимит/план года (семантика 212)
 * @param iuplpSubAg суб-агент (nullable; UK с pl+pn)
 */
public record IpgUtPlP(
        int iuplpKey,
        int iuplpPl,
        int iuplpIpgPn,
        BigDecimal iuplpLim,
        Integer iuplpSubAg
) {
}
