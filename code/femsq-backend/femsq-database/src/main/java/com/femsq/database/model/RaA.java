package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет ревизию (таблица {@code ags.ra_a}) для DAO-слоя.
 *
 * @param adtKey      идентификатор ревизии (PRIMARY KEY)
 * @param adtName     название ревизии
 * @param adtDate     дата и время выполнения ревизии
 * @param adtResults  HTML-результаты ревизии
 * @param adtDir      идентификатор директории (FK → ra_dir.key)
 * @param adtType     идентификатор типа ревизии (FK → ra_at.at_key)
 * @param adtAddRA    флаг автодобавления отсутствующих отчётов
 * @param adtCreated  дата создания записи
 * @param adtUpdated  дата последнего обновления записи
 */
public record RaA(
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
    public RaA {
        Objects.requireNonNull(adtName, "adtName");
        Objects.requireNonNull(adtDir, "adtDir");
        Objects.requireNonNull(adtType, "adtType");
        Objects.requireNonNull(adtAddRA, "adtAddRA");
    }
}