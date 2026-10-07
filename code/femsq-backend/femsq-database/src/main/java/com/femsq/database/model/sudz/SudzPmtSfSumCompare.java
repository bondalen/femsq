package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.util.List;

/**
 * Сверка итога сальдо платежей по присвоению СФ с долгом связанного свода.
 *
 * @param anchorSum Σ {@code ciputBlns} по пакету и присвоению
 * @param anchorRows число строк Tbl в группе
 * @param linked есть строка {@code cn_inv_dbt_upl_g_p} у пакета
 * @param matches строки свода с тем же номером СФ и счётом ГК
 */
public record SudzPmtSfSumCompare(
        BigDecimal anchorSum,
        int anchorRows,
        boolean linked,
        List<SudzPmtSfSumMatch> matches
) {
}
