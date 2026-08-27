package com.femsq.database.model.sudz;

/**
 * Кандидат {@code invNum} для create {@code invDbtVar} на экране двоящих.
 *
 * @param inKey {@code ags.invNum.inKey}
 * @param inInv {@code ags.inv.iKey}
 * @param inNumNull номер СФ
 */
public record SudzInvDbtVarInvNumCandidate(
        int inKey,
        int inInv,
        String inNumNull
) {
}
