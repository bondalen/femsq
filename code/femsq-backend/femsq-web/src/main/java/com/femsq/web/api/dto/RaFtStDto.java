package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление типа источника данных {@code ags.ra_ft_st} для REST API.
 *
 * @param stKey     идентификатор типа источника
 * @param stName    название типа источника
 * @param stCreated дата создания записи
 * @param stUpdated дата последнего обновления записи
 */
public record RaFtStDto(
        Integer stKey,
        String stName,
        LocalDateTime stCreated,
        LocalDateTime stUpdated
) {
}
