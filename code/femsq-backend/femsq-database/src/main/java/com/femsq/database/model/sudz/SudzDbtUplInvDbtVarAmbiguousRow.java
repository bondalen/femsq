package com.femsq.database.model.sudz;

/**
 * Контекст шага {@code invDbtVarEnsure}, где FK {@code cnNum}/{@code invNum}
 * не резолвятся однозначно.
 *
 * @param cnName номер договора
 * @param cnInv номер СФ
 * @param iKey ключ СФ
 * @param reason краткая причина (cnn|invNum|both)
 */
public record SudzDbtUplInvDbtVarAmbiguousRow(
        String cnName,
        String cnInv,
        int iKey,
        String reason
) {
}
