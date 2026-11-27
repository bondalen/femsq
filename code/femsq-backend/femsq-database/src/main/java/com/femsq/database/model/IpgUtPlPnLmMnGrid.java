package com.femsq.database.model;

import java.math.BigDecimal;
import java.util.List;

/**
 * Грид помесячных планов по заголовку UtPlP (канон LmMn + legacy lim).
 *
 * @param plPnKey заголовок
 * @param limYear {@code iuplpLim} (семантика 212)
 * @param months  12 осей C (sparse → null-поля)
 * @param cells   сырые ячейки LmMn
 * @param gAggOk  gate G-agg: оси C согласованы (нет BLOCK-δ)
 */
public record IpgUtPlPnLmMnGrid(
        int plPnKey,
        BigDecimal limYear,
        List<IpgUtPlPnLmMnMonth> months,
        List<IpgUtPlPnLmMnCell> cells,
        boolean gAggOk
) {
}
