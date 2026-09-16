package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Снимок шага {@code dbtValueLoad} (C2): skip / tail / diff / очередь P1.
 *
 * @param baseUpl {@code yr.cn_inv_dbt_upl} или null, если год не найден
 * @param skippedValues слотов с {@code DbtValue} на curr (skip)
 * @param tailReady однозначных Excel→слот кандидатов на догон Value
 * @param tailAmbiguous строк Excel без однозначного слота/{@code idvvKey} для Value
 * @param disappeared исчезнувших {@code Dbt} (base Value, нет Value на curr слоте)
 * @param p1Queued строк очереди P1 после rebuild
 * @param p1Open открытых строк P1
 * @param varInvMismatch Value на curr, у которых {@code invDbtVar.invNum} ≠ СФ в Tbl/своде
 *                       (тот же {@code iKey} + сумма ±0.01)
 * @param continuity строки dry-лога непрерывности (1 Excel + N слотов на iKey)
 */
public record SudzDbtUplDbtValueLoadSnapshot(
        Integer baseUpl,
        int skippedValues,
        int tailReady,
        int tailAmbiguous,
        int disappeared,
        int p1Queued,
        int p1Open,
        int varInvMismatch,
        List<SudzDbtUplContinuityRow> continuity
) {
    /**
     * Снимок без строк непрерывности.
     */
    public SudzDbtUplDbtValueLoadSnapshot(
            Integer baseUpl,
            int skippedValues,
            int tailReady,
            int tailAmbiguous,
            int disappeared,
            int p1Queued,
            int p1Open,
            int varInvMismatch
    ) {
        this(baseUpl, skippedValues, tailReady, tailAmbiguous, disappeared,
                p1Queued, p1Open, varInvMismatch, List.of());
    }
}
