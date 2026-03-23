package com.femsq.database.model;

/**
 * Конфигурация соответствия Excel-колонки и staging-колонки (таблица {@code ags.ra_col_map}).
 *
 * @param rcmKey       ключ записи маппинга
 * @param rcmRscKey    ссылка на {@code ra_sheet_conf.rsc_key}
 * @param rcmTblCol    имя колонки staging-таблицы
 * @param rcmTblColOrd порядковый номер колонки
 * @param rcmXlHdr     заголовок колонки Excel
 * @param rcmXlHdrPri  приоритет алиаса заголовка
 * @param rcmXlMatch   режим матчинга (W/P)
 * @param rcmRequired  признак обязательности колонки
 */
public record RaColMap(
        Integer rcmKey,
        Integer rcmRscKey,
        String rcmTblCol,
        Integer rcmTblColOrd,
        String rcmXlHdr,
        Integer rcmXlHdrPri,
        String rcmXlMatch,
        Boolean rcmRequired
) {
}
