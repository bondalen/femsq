package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Кандидат канона Dbt в результатах поиска (S78).
 *
 * @param dbtKey ключ канона
 * @param slotCount число слотов с мостом на канон
 * @param cnNum образец номера договора
 * @param invNum образец номера СФ
 * @param orgBuirg образец БУиРГ
 * @param orgName краткое имя организации ({@code og.ogNm})
 * @param csoDate образец даты стороны
 * @param idNumMin минимальный {@code idNum} среди слотов
 * @param idNumMax максимальный {@code idNum}
 * @param lastTtlSum сумма ttl Value на максимальной upl среди слотов (если есть)
 */
public record SudzDbtCanonCandidate(
        int dbtKey,
        int slotCount,
        String cnNum,
        String invNum,
        Integer orgBuirg,
        String orgName,
        LocalDate csoDate,
        Integer idNumMin,
        Integer idNumMax,
        BigDecimal lastTtlSum
) {
}
