package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Строка итогового документа D644 ({@code sudz.Yr_DbtChangesD644}).
 */
public record SudzD644Row(
        int dbtKey,
        Integer accountNum,
        String agent,
        Long orgId,
        String itn,
        String counterpart,
        String contract,
        LocalDate contractDate,
        String invoice,
        LocalDate dateStart,
        LocalDate maturityBase,
        BigDecimal ttlBase,
        BigDecimal overdBase,
        LocalDate maturityCurr,
        BigDecimal overdCurr,
        BigDecimal repaid,
        String cstCode,
        String cstName,
        String comment644,
        LocalDate baseUplDate,
        LocalDate currUplDate,
        Integer baseUpl,
        Integer currUpl
) {
}
