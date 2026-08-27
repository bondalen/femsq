package com.femsq.database.model.sudz;

/**
 * Кандидат {@code cnNum} (тип 1) для create {@code invDbtVar} на экране двоящих.
 *
 * @param cnnKey {@code ags.cnNum.cnnKey}
 * @param cnKey {@code cnnCn} → договор
 * @param cnnNumNull отображаемый номер
 */
public record SudzInvDbtVarCnNumCandidate(
        int cnnKey,
        int cnKey,
        String cnnNumNull
) {
}
