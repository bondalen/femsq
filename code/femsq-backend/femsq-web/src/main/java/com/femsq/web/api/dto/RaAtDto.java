package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление типа ревизии {@code ags.ra_at} для REST API.
 *
 * @param atKey    идентификатор типа ревизии
 * @param atName   название типа ревизии
 * @param atCreated дата создания записи
 * @param atUpdated дата последнего обновления записи
 */
public record RaAtDto(
        Integer atKey,
        String atName,
        LocalDateTime atCreated,
        LocalDateTime atUpdated
) {
}