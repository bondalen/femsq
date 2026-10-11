package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Строка состава итога сальдо (1.10.3): белая Tbl с ненулевым {@code ciputBlns}.
 *
 * @param ciputKey ключ строки Tbl
 * @param docCode «№ докум.»
 * @param docDate дата документа
 * @param dbtBlns дебет
 * @param cdtBlns кредит
 * @param blns сальдо
 */
public record SudzPmtSfSumLine(
        int ciputKey,
        String docCode,
        LocalDate docDate,
        BigDecimal dbtBlns,
        BigDecimal cdtBlns,
        BigDecimal blns
) {
}
