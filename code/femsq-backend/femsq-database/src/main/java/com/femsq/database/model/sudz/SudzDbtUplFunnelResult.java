package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат stub/реального прогона воронки загрузки свода.
 *
 * @param launcher актуальная карточка лаунчера (с логом)
 * @param ranSteps фактически запрошенные/пройденные шаги
 * @param stub {@code true}, если тело шагов ещё заглушка
 */
public record SudzDbtUplFunnelResult(
        SudzDbtUplLauncher launcher,
        List<String> ranSteps,
        boolean stub
) {
}
