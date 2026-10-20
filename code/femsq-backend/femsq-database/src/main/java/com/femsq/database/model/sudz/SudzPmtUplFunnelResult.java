package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат прогона воронки загрузки платежей.
 *
 * @param launcher актуальная карточка (с логом)
 * @param ranSteps пройденные шаги (включая excelToTbl при flTbl)
 * @param stub {@code true}, если были только stub cipu* (без apply)
 * @param sumsMatched {@code true}, если суммы книги и вкладки «счета, сумма» совпали
 * @param rowsMatched {@code true}, если набор строк книги и платежей совпал
 */
public record SudzPmtUplFunnelResult(
        SudzPmtUplLauncher launcher,
        List<String> ranSteps,
        boolean stub,
        boolean sumsMatched,
        boolean rowsMatched
) {
}
