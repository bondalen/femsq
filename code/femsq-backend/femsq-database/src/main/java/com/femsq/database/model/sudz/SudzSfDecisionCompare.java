package com.femsq.database.model.sudz;

/**
 * Исходы шапки сверки Excel ↔ кандидат СФ.
 * Значения: {@code yes} | {@code no} | {@code suspicious} | {@code na};
 * для стройки также {@code suffix} (совпал хвост из 6 символов кода САК);
 * для документов также {@code transfer} (код ездил на другой inv/cn).
 *
 * @param invNumVerdict номер СФ (с учётом алиасов {@code invNum})
 * @param cnVerdict договор
 * @param executorVerdict исполнитель (БУиРГ Excel ↔ preferred cn)
 * @param sumVerdict сумма
 * @param cstVerdict стройка (полный код / хвост 6 / нет)
 * @param docTransferVerdict переезды docKod: {@code transfer} | {@code na}
 */
public record SudzSfDecisionCompare(
        String invNumVerdict,
        String cnVerdict,
        String executorVerdict,
        String sumVerdict,
        String cstVerdict,
        String docTransferVerdict
) {
}
