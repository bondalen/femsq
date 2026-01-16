package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет имя источника данных (таблица {@code ags.ra_ft_sn}) для DAO-слоя.
 *
 * @param ftsnKey     идентификатор имени источника (PRIMARY KEY)
 * @param ftsnFtS     идентификатор источника/листа (FK → ra_ft_s.ft_s_key)
 * @param ftsnName    вариант имени листа Excel
 * @param ftsnCreated дата создания записи
 * @param ftsnUpdated дата последнего обновления записи
 */
public record RaFtSn(
        Integer ftsnKey,
        Integer ftsnFtS,
        String ftsnName,
        LocalDateTime ftsnCreated,
        LocalDateTime ftsnUpdated
) {
    public RaFtSn {
        Objects.requireNonNull(ftsnFtS, "ftsnFtS");
        Objects.requireNonNull(ftsnName, "ftsnName");
    }
}
