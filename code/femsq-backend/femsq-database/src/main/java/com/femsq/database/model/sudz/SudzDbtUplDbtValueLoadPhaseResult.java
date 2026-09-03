package com.femsq.database.model.sudz;

/**
 * Итог фазы {@code dbtValueLoad}: один JDBC-проход (P1 rebuild + tail apply).
 *
 * @param snapshot снимок после фазы
 * @param applyResult итог tail apply или null, если apply не выполнялся
 */
public record SudzDbtUplDbtValueLoadPhaseResult(
        SudzDbtUplDbtValueLoadSnapshot snapshot,
        SudzDbtUplDbtValueLoadApplyResult applyResult
) {
}
