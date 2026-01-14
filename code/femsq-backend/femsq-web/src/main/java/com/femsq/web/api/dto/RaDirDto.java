package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление директории ревизий {@code ags.ra_dir} для REST API.
 *
 * @param key       идентификатор директории
 * @param dirName   название директории
 * @param dir       путь к директории
 * @param dirCreated дата создания записи
 * @param dirUpdated дата последнего обновления записи
 */
public record RaDirDto(
        Integer key,
        String dirName,
        String dir,
        LocalDateTime dirCreated,
        LocalDateTime dirUpdated
) {
}