package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Сводка документа по платежам кандидата СФ.
 *
 * @param docKod «№ докум.»
 * @param pmCount число платежей
 * @param blnsSum сумма сальдо
 * @param uplNames пакеты (кратко)
 */
public record SudzSfDecisionDocSum(
        String docKod,
        int pmCount,
        BigDecimal blnsSum,
        String uplNames
) {
}
