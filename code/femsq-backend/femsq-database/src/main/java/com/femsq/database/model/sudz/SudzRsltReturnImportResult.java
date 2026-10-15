package com.femsq.database.model.sudz;

/**
 * Итог импорта возврата Rslt в {@code yr_CmmGr_New}.
 *
 * @param importedDebts сколько долгов с записью хотя бы одного поля
 * @param boundExtreme  долги, севшие на Value крайней upl
 * @param boundWalkBack долги, севшие на Value предшествующей upl (walk-back)
 * @param boundAcc      долги без Value в году — legacy Acc
 */
public record SudzRsltReturnImportResult(
        int importedDebts,
        int boundExtreme,
        int boundWalkBack,
        int boundAcc
) {
}
