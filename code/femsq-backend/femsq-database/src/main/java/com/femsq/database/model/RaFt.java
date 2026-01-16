package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет тип файла (таблица {@code ags.ra_ft}) для DAO-слоя.
 * Справочник типов файлов для проверки (lookup для ra_f.af_type).
 *
 * @param ftKey   идентификатор типа файла (PRIMARY KEY)
 * @param ftName  название типа файла (отображается в UI)
 */
public record RaFt(
        Integer ftKey,
        String ftName
) {
    public RaFt {
        Objects.requireNonNull(ftName, "ftName");
    }
}
