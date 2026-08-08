package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Lookup строки выгрузки ДЗ ({@code cn_inv_dbt_upl}).
 *
 * @param uplKey ключ выгрузки
 * @param uplName имя
 * @param uplDate дата выгрузки
 * @param uplStatusOnDate дата состояния (срез)
 */
public record SudzUplLookup(
        int uplKey,
        String uplName,
        LocalDate uplDate,
        LocalDate uplStatusOnDate
) {
}
