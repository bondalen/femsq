package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Ось C для одного месяца (212 / 195 / 172 / 187) после AggAxis.
 *
 * @param plPnKey заголовок {@code ipgUtPlP}
 * @param month   1…12
 * @param lim212  Всего
 * @param lim195  СМР
 * @param lim172  оборудование
 * @param lim187  прочие
 * @param aggCode код {@code AGG_*}
 */
public record IpgUtPlPnLmMnMonth(
        int plPnKey,
        int month,
        BigDecimal lim212,
        BigDecimal lim195,
        BigDecimal lim172,
        BigDecimal lim187,
        String aggCode
) {
}
