package com.femsq.database.model.sudz;

/**
 * Результат сохранения сбора по долгу (куратор / мероприятия / код стройки).
 *
 * @param dbtKey ключ долга
 * @param curator куратор
 * @param mery мероприятия
 * @param cstCode код стройки ({@code cstapIpgPnN})
 * @param cstName наименование стройки
 * @param cmmGr группа комментариев {@code yr.yr_CmmGr}
 */
public record SudzDebtCollection(
        int dbtKey,
        String curator,
        String mery,
        String cstCode,
        String cstName,
        int cmmGr
) {
}
