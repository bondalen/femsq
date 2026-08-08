package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Связь выгрузки ДЗ с выгрузкой платежей ({@code cn_inv_dbt_upl_g_p}).
 *
 * @param gPKey ключ связи ({@code [key]})
 * @param dbtUpl ключ выгрузки ДЗ
 * @param pmKey ключ выгрузки платежей
 * @param pmName имя выгрузки платежей
 * @param pmDate дата выгрузки платежей
 * @param dbtUplName имя выгрузки ДЗ
 * @param dbtUplDate дата выгрузки ДЗ
 */
public record SudzPmLink(
        int gPKey,
        int dbtUpl,
        int pmKey,
        String pmName,
        LocalDate pmDate,
        String dbtUplName,
        LocalDate dbtUplDate
) {
}
