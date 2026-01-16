package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет тип источника данных (таблица {@code ags.ra_ft_st}) для DAO-слоя.
 *
 * @param stKey     идентификатор типа источника (PRIMARY KEY)
 * @param stName    название типа источника
 * @param stCreated дата создания записи
 * @param stUpdated дата последнего обновления записи
 */
public record RaFtSt(
        Integer stKey,
        String stName,
        LocalDateTime stCreated,
        LocalDateTime stUpdated
) {
    public RaFtSt {
        Objects.requireNonNull(stName, "stName");
    }
}
