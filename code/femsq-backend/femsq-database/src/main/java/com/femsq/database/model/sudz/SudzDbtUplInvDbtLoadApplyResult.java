package com.femsq.database.model.sudz;

/**
 * Итог auto-apply шага {@code invDbtLoad} (однозначные слоты).
 *
 * @param insertedInvDbt число INSERT в {@code sudz.invDbt}
 * @param insertedBridges число INSERT в {@code sudz.invDbtDbtVar}
 * @param queuedCount число строк очереди {@code CnInvUplInvDbtDouble} после rebuild
 */
public record SudzDbtUplInvDbtLoadApplyResult(
        int insertedInvDbt,
        int insertedBridges,
        int queuedCount
) {
}
