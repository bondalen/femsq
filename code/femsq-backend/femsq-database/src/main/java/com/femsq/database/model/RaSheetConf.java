package com.femsq.database.model;

/**
 * Конфигурация листа Excel для загрузки в staging (таблица {@code ags.ra_sheet_conf}).
 *
 * @param rscKey         ключ конфигурации
 * @param rscFtKey       тип файла (af_type / ft_key)
 * @param rscSheet       имя листа в книге Excel (может быть null)
 * @param rscStgTbl      целевая staging-таблица
 * @param rscAnchor      якорный заголовок
 * @param rscAnchorMatch режим матчинга якоря (W/P)
 * @param rscRowPattern  шаблон строки данных (может быть null)
 */
public record RaSheetConf(
        Integer rscKey,
        Integer rscFtKey,
        String rscSheet,
        String rscStgTbl,
        String rscAnchor,
        String rscAnchorMatch,
        String rscRowPattern
) {
}
