package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Карточка год-варианта: шапка {@link SudzYear} и список выгрузок.
 *
 * @param year год с lookup-подписями
 * @param upls выгрузки {@code yr_upl_p} с вложенными pm-связями
 */
public record SudzYearDetail(
        SudzYear year,
        List<SudzYearUpl> upls
) {
}
