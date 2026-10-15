package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Срез долга в портфеле года (строка {@code sudz.vw_Yr_DbtFact}).
 * Комментарии на Value ({@code *Dv}): «старые» — с предшествующего среза группы;
 * {@code *New} — с крайней upl ({@code yr_CmmGr_New}).
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
        BigDecimal pogasheno,
        Integer dvKey,
        String curator,
        String mery,
        String cstCode,
        String cstName,
        String curatorNew,
        String meryNew,
        String cstCodeNew
) {
}
