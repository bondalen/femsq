package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Сводка документа по платежам кандидата СФ.
 *
 * @param docKod «№ докум.»
 * @param pmCount число платежей
 * @param blnsSum сумма сальдо
 * @param uplNames пакеты (кратко)
 * @param otherInvCount число других inv с тем же кодом (переезд)
 * @param otherCnCount число других договоров с тем же кодом
 * @param transferHint краткая подсказка чужого договора/СФ
 * @param hlDocTransfer true если код встречался на другом inv/cn
 */
public record SudzSfDecisionDocSum(
        String docKod,
        int pmCount,
        BigDecimal blnsSum,
        String uplNames,
        int otherInvCount,
        int otherCnCount,
        String transferHint,
        boolean hlDocTransfer
) {
}
