package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление источника данных / листа {@code ags.ra_ft_s} для REST API.
 *
 * @param ftSKey        идентификатор источника/листа
 * @param ftSType       тип файла (соответствует ra_f.af_type: 1-6)
 * @param ftSNum        номер источника/листа (для сортировки и определения порядка обработки)
 * @param ftSSheetType  тип источника (FK → ra_ft_st.st_key)
 * @param ftSCreated    дата создания записи
 * @param ftSUpdated    дата последнего обновления записи
 * @param ftSPeriod     период для источника данных (используется для определения временного интервала)
 */
public record RaFtSDto(
        Integer ftSKey,
        Integer ftSType,
        Integer ftSNum,
        Integer ftSSheetType,
        LocalDateTime ftSCreated,
        LocalDateTime ftSUpdated,
        String ftSPeriod
) {
}
