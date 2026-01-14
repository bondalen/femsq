package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление ревизии {@code ags.ra_a} для REST API.
 *
 * @param adtKey     идентификатор ревизии
 * @param adtName    название ревизии
 * @param adtDate    дата и время выполнения ревизии
 * @param adtResults HTML-результаты ревизии
 * @param adtDir     идентификатор директории (FK → ra_dir.key)
 * @param adtType    идентификатор типа ревизии (FK → ra_at.at_key)
 * @param adtAddRA   флаг автодобавления отсутствующих отчётов
 * @param adtCreated дата создания записи
 * @param adtUpdated дата последнего обновления записи
 */
public record RaADto(
        Long adtKey,
        String adtName,
        LocalDateTime adtDate,
        String adtResults,
        Integer adtDir,
        Integer adtType,
        Boolean adtAddRA,
        LocalDateTime adtCreated,
        LocalDateTime adtUpdated
) {
}