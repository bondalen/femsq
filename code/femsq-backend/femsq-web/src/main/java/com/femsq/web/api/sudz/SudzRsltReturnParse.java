package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltReturnRow;
import java.util.List;

/**
 * Результат разбора возврата Rslt до записи в базу.
 *
 * @param rows одна строка на {@code dbtKey} после склейки полосы
 * @param sourceRows физические строки листа с непустым {@code *_new}
 * @param sameTextKeys долги, у которых несколько строк полосы несут один текст
 * @param differentTextKeys долги, у которых непустые тексты одной колонки разошлись;
 *                          в {@code rows} остаётся нижняя строка
 */
public record SudzRsltReturnParse(
        List<SudzRsltReturnRow> rows,
        int sourceRows,
        List<Integer> sameTextKeys,
        List<Integer> differentTextKeys
) {
}
