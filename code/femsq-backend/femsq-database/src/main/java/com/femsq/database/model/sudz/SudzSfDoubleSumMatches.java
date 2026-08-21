package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Кандидаты вкладки «Суммы» КСДСФ: старая и новая структуры.
 *
 * @param oldMatches {@code ags.cn_inv_dbt} по {@code dbt_ttl}
 * @param newMatches {@code sudz.DbtValue} по {@code dvTtl}
 */
public record SudzSfDoubleSumMatches(
        List<SudzSfDoubleOldSumMatch> oldMatches,
        List<SudzSfDoubleNewSumMatch> newMatches
) {
}
