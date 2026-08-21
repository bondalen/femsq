package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Совпадение суммы с Excel в старой структуре ({@code ags.cn_inv_dbt}).
 *
 * @param cidKey {@code cn_inv_dbt_key}
 * @param number номер строки ДЗ
 * @param dbtTtl сумма
 * @param dbtOverd просрочка
 * @param debtType тип долга
 * @param uplKey выгрузка
 * @param ciaKey счёт/контрагент ({@code cidCnInvAccntCtpt})
 */
public record SudzSfDoubleOldSumMatch(
        int cidKey,
        Integer number,
        BigDecimal dbtTtl,
        BigDecimal dbtOverd,
        String debtType,
        Integer uplKey,
        Integer ciaKey
) {
}
