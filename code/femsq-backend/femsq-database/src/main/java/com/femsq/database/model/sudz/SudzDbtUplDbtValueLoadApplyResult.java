package com.femsq.database.model.sudz;

/**
 * Итог apply шага {@code dbtValueLoad} (C2 / M5).
 *
 * @param insertedValues число INSERT {@code DbtValue} (догон хвостов)
 * @param skippedTailAmbiguous пропущено tail (неоднозначный var)
 * @param p1Queued строк P1 после rebuild очереди
 */
public record SudzDbtUplDbtValueLoadApplyResult(
        int insertedValues,
        int skippedTailAmbiguous,
        int p1Queued
) {
}
