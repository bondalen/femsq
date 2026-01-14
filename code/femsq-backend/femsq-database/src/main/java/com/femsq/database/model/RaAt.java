package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет тип ревизии (таблица {@code ags.ra_at}) для DAO-слоя.
 *
 * @param atKey    идентификатор типа ревизии (PRIMARY KEY)
 * @param atName   название типа ревизии
 * @param atCreated дата создания записи
 * @param atUpdated дата последнего обновления записи
 */
public record RaAt(
        Integer atKey,
        String atName,
        LocalDateTime atCreated,
        LocalDateTime atUpdated
) {
    public RaAt {
        Objects.requireNonNull(atName, "atName");
    }
}