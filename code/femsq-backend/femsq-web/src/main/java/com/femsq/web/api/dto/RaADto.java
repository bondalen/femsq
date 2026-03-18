package com.femsq.web.api.dto;

import java.time.OffsetDateTime;

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
 * @param adtStatus  технический статус выполнения (in-memory): IDLE/RUNNING/COMPLETED/FAILED
 */
public record RaADto(
        Long adtKey,
        String adtName,
        OffsetDateTime adtDate,
        String adtResults,
        Integer adtDir,
        Integer adtType,
        Boolean adtAddRA,
        OffsetDateTime adtCreated,
        OffsetDateTime adtUpdated,
        String adtStatus
) {
}