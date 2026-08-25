package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Снимок шага {@code invDbtVarEnsure}: missing и ambiguous из одного прохода CTE.
 *
 * @param missing однозначные контексты без {@code invDbtVar}
 * @param ambiguous контексты с неоднозначным {@code cnNum}/{@code invNum}
 */
public record SudzDbtUplInvDbtVarEnsureSnapshot(
        List<SudzDbtUplInvDbtVarEnsureRow> missing,
        List<SudzDbtUplInvDbtVarAmbiguousRow> ambiguous
) {
}
