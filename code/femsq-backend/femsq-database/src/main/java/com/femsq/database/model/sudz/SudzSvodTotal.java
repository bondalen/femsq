package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Итог «ВСЕГО» годового свода.
 */
public record SudzSvodTotal(
        BigDecimal overdBase,
        BigDecimal repaid,
        BigDecimal overdCurr,
        Double repaidPct
) {
}
