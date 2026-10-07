package com.femsq.database.model;

/**
 * Поколоночный фильтр страницы связей cnInv.
 * Пустая строка поле не сужает. Номер СФ сравнивается с {@code invNum.inNum}.
 */
public record CnInvColumnFilters(
        String iNum,
        String ciInv,
        String ciKey,
        String ciTimeOfEntry
) {
}
