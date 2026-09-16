package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат прогона воронки загрузки платежей.
 *
 * @param launcher актуальная карточка (с логом)
 * @param ranSteps пройденные шаги (включая excelToTbl при flTbl)
 * @param stub {@code true}, если были только stub cipu* (без apply)
 */
public record SudzPmtUplFunnelResult(
        SudzPmtUplLauncher launcher,
        List<String> ranSteps,
        boolean stub
) {
}
