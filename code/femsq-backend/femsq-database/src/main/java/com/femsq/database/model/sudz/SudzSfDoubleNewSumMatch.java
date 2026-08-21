package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Совпадение суммы с Excel в новой структуре ({@code sudz.DbtValue}).
 *
 * @param dvKey {@code dvKey}
 * @param dvTtl сумма
 * @param dvOverd просрочка
 * @param dvUpl выгрузка
 * @param dvDbt ключ {@code Dbt}
 */
public record SudzSfDoubleNewSumMatch(
        int dvKey,
        BigDecimal dvTtl,
        BigDecimal dvOverd,
        Integer dvUpl,
        Integer dvDbt
) {
}
