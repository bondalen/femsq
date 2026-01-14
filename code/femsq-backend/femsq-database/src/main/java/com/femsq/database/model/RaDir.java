package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет директорию для ревизий (таблица {@code ags.ra_dir}) для DAO-слоя.
 *
 * @param key       идентификатор директории (PRIMARY KEY)
 * @param dirName   название директории
 * @param dir       путь к директории
 * @param dirCreated дата создания записи
 * @param dirUpdated дата последнего обновления записи
 */
public record RaDir(
        Integer key,
        String dirName,
        String dir,
        LocalDateTime dirCreated,
        LocalDateTime dirUpdated
) {
    public RaDir {
        Objects.requireNonNull(dirName, "dirName");
        Objects.requireNonNull(dir, "dir");
    }
}