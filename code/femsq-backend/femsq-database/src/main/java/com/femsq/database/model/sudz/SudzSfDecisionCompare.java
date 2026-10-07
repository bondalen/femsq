package com.femsq.database.model.sudz;

/**
 * Исходы шапки сверки Excel ↔ кандидат СФ.
 * Значения: {@code yes} | {@code no} | {@code suspicious} | {@code na};
 * для стройки также {@code suffix} (совпал хвост из 6 символов кода САК).
 *
 * @param invNumVerdict номер СФ
 * @param cnVerdict договор
 * @param executorVerdict исполнитель (БУиРГ Excel ↔ preferred cn)
 * @param sumVerdict сумма
 * @param cstVerdict стройка (полный код / хвост 6 / нет)
 */
public record SudzSfDecisionCompare(
        String invNumVerdict,
        String cnVerdict,
        String executorVerdict,
        String sumVerdict,
        String cstVerdict
) {
}
