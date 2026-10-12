package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input сохранения сбора СУДЗ.
 *
 * @param yr ключ года
 * @param dbtKey ключ долга
 * @param curator куратор
 * @param mery мероприятия
 * @param cstCode код стройки
 * @param writeToNew {@code true} — писать в {@code yr_CmmGr_New}
 */
public record SudzDebtCollectionInput(
        int yr,
        int dbtKey,
        String curator,
        String mery,
        String cstCode,
        Boolean writeToNew
) {
}
