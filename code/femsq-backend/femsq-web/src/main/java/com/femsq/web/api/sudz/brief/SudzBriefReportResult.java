package com.femsq.web.api.sudz.brief;

import java.util.List;

/**
 * Результат прогона краткого отчёта (**1.1.1.0.3.2**).
 *
 * @param outputPath абсолютный путь записанного файла (строка для GraphQL)
 * @param logLines строки Progress
 * @param fioTransformed сколько C сокращено до инициалов
 * @param fioSkipWordcount пропуски ≠3 слов
 * @param fioSkipDict пропуски «не в словаре»
 * @param totalDebtH сумма ВСЕГО по H
 * @param totalOverdueI сумма ВСЕГО по I
 * @param totalNotOverdueK сумма ВСЕГО по K
 * @param accountBlocks коды СГК в порядке блоков
 */
public record SudzBriefReportResult(
        String outputPath,
        List<String> logLines,
        int fioTransformed,
        int fioSkipWordcount,
        int fioSkipDict,
        double totalDebtH,
        double totalOverdueI,
        double totalNotOverdueK,
        List<String> accountBlocks
) {
}
