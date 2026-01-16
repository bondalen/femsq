package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет источник данных / лист (таблица {@code ags.ra_ft_s}) для DAO-слоя.
 *
 * @param ftSKey        идентификатор источника/листа (PRIMARY KEY)
 * @param ftSType       тип файла (соответствует ra_f.af_type: 1-6)
 * @param ftSNum        номер источника/листа (для сортировки и определения порядка обработки)
 * @param ftSSheetType  тип источника (FK → ra_ft_st.st_key)
 * @param ftSCreated    дата создания записи
 * @param ftSUpdated    дата последнего обновления записи
 * @param ftSPeriod     период для источника данных (используется для определения временного интервала)
 */
public record RaFtS(
        Integer ftSKey,
        Integer ftSType,
        Integer ftSNum,
        Integer ftSSheetType,
        LocalDateTime ftSCreated,
        LocalDateTime ftSUpdated,
        String ftSPeriod
) {
    public RaFtS {
        Objects.requireNonNull(ftSType, "ftSType");
        Objects.requireNonNull(ftSNum, "ftSNum");
        Objects.requireNonNull(ftSSheetType, "ftSSheetType");
    }
}
