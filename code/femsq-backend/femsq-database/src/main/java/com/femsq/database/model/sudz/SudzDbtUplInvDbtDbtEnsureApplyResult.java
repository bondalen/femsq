package com.femsq.database.model.sudz;

/**
 * Итог apply шага {@code invDbtDbtEnsure} (C1 / M5).
 *
 * @param reusedF1 число мостов через reuse {@code Dbt} (F1 / D2)
 * @param insertedDbt число INSERT в {@code sudz.Dbt}
 * @param insertedBridges число INSERT в {@code sudz.invDbtDbt}
 * @param skippedAmbiguous пропущено (неоднозначно)
 */
public record SudzDbtUplInvDbtDbtEnsureApplyResult(
        int reusedF1,
        int insertedDbt,
        int insertedBridges,
        int skippedAmbiguous
) {
}
