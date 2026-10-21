package com.femsq.web.api.sudz.repay;

import java.util.List;

/**
 * Результат «Проверить погашения» (S79, шаг 2A). Файл Excel не строится.
 *
 * @param yrKey год-вариант
 * @param asOfUpl крайняя выгрузка
 * @param candidateCount строки с ненулевым «погашено»
 * @param likelyTrueCount класс likely-true
 * @param suspectCount класс suspect — единственный порог перед выгрузкой
 * @param ambiguousCount класс ambiguous (в таблице, выгрузку не закрывает)
 * @param documentedCount белый список
 * @param logText протокол прогона
 * @param openCases suspect и ambiguous
 */
public record SudzRsltRepaymentCheck(
        int yrKey,
        int asOfUpl,
        int candidateCount,
        int likelyTrueCount,
        int suspectCount,
        int ambiguousCount,
        int documentedCount,
        String logText,
        List<SudzRsltRepaymentCase> openCases
) {
}
