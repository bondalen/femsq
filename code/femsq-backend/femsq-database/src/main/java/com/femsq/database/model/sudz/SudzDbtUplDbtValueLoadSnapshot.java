package com.femsq.database.model.sudz;

/**
 * Снимок шага {@code dbtValueLoad} (C2): skip / tail / diff / очередь P1.
 *
 * @param baseUpl {@code yr.cn_inv_dbt_upl} или null, если год не найден
 * @param skippedValues слотов с {@code DbtValue} на curr (skip)
 * @param tailReady слотов с мостом в Tbl без Value на curr (догон)
 * @param tailAmbiguous tail с неоднозначным {@code invDbtVar}
 * @param disappeared исчезнувших {@code Dbt} (base Value, нет Value на curr слоте)
 * @param p1Queued строк очереди P1 после rebuild
 * @param p1Open открытых строк P1
 */
public record SudzDbtUplDbtValueLoadSnapshot(
        Integer baseUpl,
        int skippedValues,
        int tailReady,
        int tailAmbiguous,
        int disappeared,
        int p1Queued,
        int p1Open
) {
}
