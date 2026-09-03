package com.femsq.database.model.sudz;

/**
 * Итог объединённой фазы AccSmpl → invDbtVarEnsure → invDbtLoad (одно соединение).
 *
 * @param accSmpl итог apply AccSmpl или null
 * @param varEnsure итог apply invDbtVarEnsure или null
 * @param invDbtLoad итог rebuild/apply invDbtLoad
 */
public record SudzDbtUplAccSmplVarInvPhaseResult(
        SudzDbtUplAccSmplNotApplyResult accSmpl,
        SudzDbtUplInvDbtVarEnsureApplyResult varEnsure,
        SudzDbtUplInvDbtLoadApplyResult invDbtLoad
) {
}
