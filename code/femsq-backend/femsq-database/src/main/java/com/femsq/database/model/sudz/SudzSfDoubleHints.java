package com.femsq.database.model.sudz;

/**
 * Подсказки КСДСФ: есть ли исполнитель Excel среди СФ по номеру и сумм.
 *
 * @param sfByNum зона «Счета-фактуры»
 * @param sumsOld зона «Суммы · cn_inv_dbt»
 * @param sumsNew зона «Суммы · DbtValue»
 */
public record SudzSfDoubleHints(
        SudzSfDoubleHintSection sfByNum,
        SudzSfDoubleHintSection sumsOld,
        SudzSfDoubleHintSection sumsNew
) {
}
