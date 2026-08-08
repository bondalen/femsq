package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input сохранения сбора СУДЗ.
 *
 * @param yr ключ года
 * @param dbtKey ключ долга
 * @param curator куратор
 * @param mery мероприятия
 * @param cstCode код стройки
 */
public record SudzDebtCollectionInput(
        int yr,
        int dbtKey,
        String curator,
        String mery,
        String cstCode
) {
}
