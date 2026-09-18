package com.femsq.database.model.sudz;

/**
 * Ключи, созданные apply шага 5 для одной строки.
 *
 * @param cnSKey сторона {@code cn_s} type=1
 * @param csosKey {@code cn_s_org_smpl}
 * @param cnSOrgKey {@code cn_s_org}
 * @param createdCnS была ли создана сторона type=1 в этом apply
 */
public record SudzPmtUplAgNotLoadInserted(
        int cnSKey,
        int csosKey,
        int cnSOrgKey,
        boolean createdCnS
) {
}
