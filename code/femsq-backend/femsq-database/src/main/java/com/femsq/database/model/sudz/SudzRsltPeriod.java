package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Срез долга в портфеле года (строка {@code sudz.vw_Yr_DbtFact}).
 */
public record SudzRsltPeriod(
        int uplKey,
        LocalDate uplDate,
        LocalDate asOf,
        String invNumEnum,
        Integer idNum,
        String cnNumEnum,
        LocalDate csoCnDate,
        Long orgIdValueL,
        String itn,
        String ctptOrg,
        LocalDate maturity,
        BigDecimal ttl,
        BigDecimal overd,
        String cstAgPnCode,
        String cstAgPnName,
        String agOrg,
        BigDecimal pogasheno
) {
}
