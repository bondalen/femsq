package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Год-вариант СУДЗ ({@code yr}) с подписями lookup для экрана «Портфель года».
 *
 * @param yrKey ключ года
 * @param yrVariant описание варианта
 * @param baseUpl базовая выгрузка портфеля ({@code cn_inv_dbt_upl})
 * @param yyyy ключ {@code ags.yyyy.yKey}
 * @param cmmGr актуальная группа комментариев ({@code yr_CmmGr})
 * @param baseUplName имя базовой выгрузки
 * @param baseUplDate дата базовой выгрузки
 * @param cmmGrName имя группы комментариев
 * @param cmmGrDate дата группы комментариев
 * @param cmmGrNew рабочая группа новых ({@code yr_CmmGr_New})
 * @param cmmGrNewName имя группы новых
 * @param cmmGrNewDate дата группы новых
 * @param yyyyValue календарный год из {@code ags.yyyy.yyyy}
 * @param progress HTML-лог хода ({@code yr_Progress}, только чтение)
 */
public record SudzYear(
        int yrKey,
        String yrVariant,
        Integer baseUpl,
        Integer yyyy,
        Integer cmmGr,
        String baseUplName,
        LocalDate baseUplDate,
        String cmmGrName,
        LocalDate cmmGrDate,
        Integer cmmGrNew,
        String cmmGrNewName,
        LocalDate cmmGrNewDate,
        Integer yyyyValue,
        String progress
) {
}
