package com.femsq.database.model.sudz;

/**
 * Итог auto-apply шага {@code invDbtLoad} (однозначные слоты + Value M2).
 *
 * @param insertedInvDbt число INSERT в {@code sudz.invDbt}
 * @param insertedBridges число INSERT в {@code sudz.invDbtDbtVar}
 * @param insertedValues число INSERT в {@code sudz.DbtValue}
 * @param queuedCount число строк очереди {@code CnInvUplInvDbtDouble} после apply
 */
public record SudzDbtUplInvDbtLoadApplyResult(
        int insertedInvDbt,
        int insertedBridges,
        int insertedValues,
        int queuedCount
) {
}
