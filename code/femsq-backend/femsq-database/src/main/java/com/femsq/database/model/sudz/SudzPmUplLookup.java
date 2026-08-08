package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Lookup выгрузки платежей ({@code cn_inv_pm_upl}).
 *
 * @param pmKey ключ
 * @param name имя
 * @param date дата
 */
public record SudzPmUplLookup(
        int pmKey,
        String name,
        LocalDate date
) {
}
