package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Строка годового свода по счёту ГК.
 */
public record SudzSvodAccount(
        int accountNum,
        String accountName,
        BigDecimal overdBase,
        BigDecimal repaid,
        BigDecimal overdCurr,
        Double repaidPct
) {
}
