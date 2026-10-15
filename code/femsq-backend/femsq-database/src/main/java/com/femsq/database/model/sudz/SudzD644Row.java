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
        Integer currUpl,
        /** Порядковый номер строки внутри полосы долга, с 1. */
        int bandRn,
        /** Сколько строк вниз сливает колонки базы. 0 — ячейка пустая, она внутри чужой склейки. */
        int baseSpan,
        /** Сколько строк вниз сливает колонки среза. */
        int currSpan,
        /** Сколько строк вниз сливает комментарий, код и агента. Зерно — Value среза ({@code yr_CmmGr}). */
        int commentSpan,
        /** Сколько строк вниз сливает «погашено» (канон долга). */
        int repaidSpan
) {
}
