package com.femsq.database.model.sudz;

/**
 * Строка импорта возврата Rslt (колонки {@code *_new}).
 *
 * @param dbtKey ключ долга
 * @param curatorNew куратор ({@code cur_new})
 * @param meryNew мероприятия ({@code mery_new})
 * @param cstCodeNew код стройки ({@code cstAgPn_new})
 */
public record SudzRsltReturnRow(
        int dbtKey,
        String curatorNew,
        String meryNew,
        String cstCodeNew
) {
}
