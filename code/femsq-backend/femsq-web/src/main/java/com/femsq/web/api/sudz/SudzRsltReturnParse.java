package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltReturnRow;
import java.util.List;

/**
 * Результат разбора возврата Rslt до записи в базу.
 *
 * @param rows строки полосы с {@code bandOrdinal} (несколько на один {@code dbtKey} при split)
 * @param sourceRows физические строки листа с непустым {@code *_new}
 * @param sameTextKeys долги, у которых несколько строк полосы несут один текст
 * @param differentTextKeys долги, у которых непустые тексты одной колонки разошлись;
 *                          каждая строка полосы пишется на свою Value
 */
public record SudzRsltReturnParse(
        List<SudzRsltReturnRow> rows,
        int sourceRows,
        List<Integer> sameTextKeys,
        List<Integer> differentTextKeys
) {
}
