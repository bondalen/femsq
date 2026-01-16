package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление имени источника данных {@code ags.ra_ft_sn} для REST API.
 *
 * @param ftsnKey     идентификатор имени источника
 * @param ftsnFtS     идентификатор источника/листа (FK → ra_ft_s.ft_s_key)
 * @param ftsnName    вариант имени листа Excel
 * @param ftsnCreated дата создания записи
 * @param ftsnUpdated дата последнего обновления записи
 */
public record RaFtSnDto(
        Integer ftsnKey,
        Integer ftsnFtS,
        String ftsnName,
        LocalDateTime ftsnCreated,
        LocalDateTime ftsnUpdated
) {
}
