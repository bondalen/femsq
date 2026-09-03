package com.femsq.database.model.sudz;

/**
 * Счётчики DELETE при сбросе очередей/буферов воронки загрузки свода для одной выгрузки.
 *
 * @param sfDoubleDeleted строк {@code CnInvUplSfDouble} (КСДСФ)
 * @param invDbtDoubleDeleted строк {@code CnInvUplInvDbtDouble} (КСДД)
 * @param fileInvDoubleDeleted строк {@code CnInvDbtUplFileInvDouble}
 * @param tblCnInvDeleted строк {@code CnInvDbtUplTblCnInv}
 * @param dbtP1Deleted строк {@code CnInvUplDbtP1}
 */
public record SudzDbtUplFunnelQueueClearResult(
        int sfDoubleDeleted,
        int invDbtDoubleDeleted,
        int fileInvDoubleDeleted,
        int tblCnInvDeleted,
        int dbtP1Deleted
) {
}
