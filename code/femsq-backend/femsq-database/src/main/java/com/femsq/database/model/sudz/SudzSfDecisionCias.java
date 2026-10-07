package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Счёт ГК (cias) кандидата СФ.
 *
 * @param ciasKey ключ cias
 * @param ciKey cnInv
 * @param accountNum номер счёта
 * @param pmCount число платежей
 * @param blnsSum сумма сальдо
 */
public record SudzSfDecisionCias(
        int ciasKey,
        int ciKey,
        String accountNum,
        int pmCount,
        BigDecimal blnsSum
) {
}
