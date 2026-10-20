package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Связи {@code cn_inv_dbt_upl_g_p} выбранного пакета платежей и остальные пакеты тех же сводов.
 * Запись связи не выполняет.
 *
 * @param links строки g_p этого пакета
 * @param cohort пакеты тех же сводов, кроме выбранного
 */
public record SudzPmtUplGp(
        List<SudzPmLink> links,
        List<SudzPmLink> cohort
) {
}
