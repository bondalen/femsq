package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Ячейка канона месяц × stCost ({@code ags.ipgUtPlPnLmMn}).
 *
 * @param iuplpmKey    PK
 * @param iuplpmPlPn   заголовок {@code ipgUtPlP}
 * @param iuplpmStCost код затрат
 * @param iuplpmMn     месяц 1…12
 * @param iuplpmLim    сумма млн ₽
 */
public record IpgUtPlPnLmMnCell(
        int iuplpmKey,
        int iuplpmPlPn,
        int iuplpmStCost,
        int iuplpmMn,
        BigDecimal iuplpmLim
) {
}
