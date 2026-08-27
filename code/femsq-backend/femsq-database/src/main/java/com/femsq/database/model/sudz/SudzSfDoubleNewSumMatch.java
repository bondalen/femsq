package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Совпадение суммы с Excel в новой структуре ({@code sudz.DbtValue}, M2).
 *
 * @param dvKey {@code dvKey}
 * @param dvTtl сумма
 * @param dvOverd просрочка
 * @param dvUpl выгрузка
 * @param dvInvDbt якорь слота {@code invDbt}
 * @param dbtKey выводимый канон {@code Dbt} через {@code invDbtDbt} (может быть null)
 */
public record SudzSfDoubleNewSumMatch(
        int dvKey,
        BigDecimal dvTtl,
        BigDecimal dvOverd,
        Integer dvUpl,
        Integer dvInvDbt,
        Integer dbtKey
) {
}
