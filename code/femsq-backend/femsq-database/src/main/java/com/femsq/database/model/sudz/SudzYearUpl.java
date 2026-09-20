package com.femsq.database.model.sudz;

import java.time.LocalDate;
import java.util.List;

/**
 * Выгрузка в составе года ({@code yr_upl_p}) с lookup и связями платежей.
 *
 * @param yrUplPKey ключ строки {@code yr_upl_p}
 * @param yrKey ключ года
 * @param uplKey ключ выгрузки ДЗ
 * @param uplName имя выгрузки
 * @param uplDate дата выгрузки
 * @param uplStatusOnDate дата состояния
 * @param pmLinks связи с выгрузками платежей
 * @param opsProgress HTML-лог операций File ({@code cidufOpsProgress}), nullable
 */
public record SudzYearUpl(
        int yrUplPKey,
        int yrKey,
        int uplKey,
        String uplName,
        LocalDate uplDate,
        LocalDate uplStatusOnDate,
        List<SudzPmLink> pmLinks,
        String opsProgress
) {
}
