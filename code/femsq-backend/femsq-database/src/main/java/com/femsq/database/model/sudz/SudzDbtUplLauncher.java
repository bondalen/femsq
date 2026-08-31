package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Карточка лаунчера загрузки свода для выбранной выгрузки.
 *
 * @param upl реестр {@code cn_inv_dbt_upl}
 * @param file шапка File (null, если ещё нет строки staging)
 * @param sheets листы FileSh
 * @param invDoubles legacy очередь {@code FileInvDouble} (может быть пуста после S68)
 * @param sfDoubles общая очередь {@code CnInvUplSfDouble} (КСДСФ)
 * @param invDbtDoubles очередь {@code CnInvUplInvDbtDouble} (двоящие долги СФ, S66e)
 * @param dbtP1 очередь {@code CnInvUplDbtP1} (кандидаты multi-Dbt P1, C2)
 */
public record SudzDbtUplLauncher(
        SudzUplLookup upl,
        SudzDbtUplFile file,
        List<SudzDbtUplFileSh> sheets,
        List<SudzDbtUplInvDouble> invDoubles,
        List<SudzCnInvUplSfDouble> sfDoubles,
        List<SudzCnInvUplInvDbtDouble> invDbtDoubles,
        List<SudzCnInvUplDbtP1> dbtP1
) {
}
