package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Связь СФ с договором ({@code cnInv}) и стороны договора.
 *
 * @param ciKey {@code cnInv.ciKey}
 * @param cnKey договор
 * @param contract номер/имя договора
 * @param note note cnInv
 * @param executors исполнители ({@code cn_s_type=2})
 * @param agents агенты ({@code cn_s_type=1})
 */
public record SudzSfDecisionCnInv(
        int ciKey,
        Integer cnKey,
        String contract,
        String note,
        List<SudzSfDecisionParty> executors,
        List<SudzSfDecisionParty> agents
) {
}
