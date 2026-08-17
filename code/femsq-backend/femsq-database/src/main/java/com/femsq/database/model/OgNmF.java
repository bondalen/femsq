package com.femsq.database.model;

import java.time.LocalDate;

/**
 * Вариант наименования организации ({@code ags.ogNmF}) — «разные имена для ловли».
 *
 * @param onfKey PK
 * @param onfOg FK → {@code og.ogKey}
 * @param onfName организация (для сопоставления)
 * @param onfNameExt филиал / расширение имени
 * @param onfStart начало актуальности
 * @param onfEnd завершение актуальности
 */
public record OgNmF(
        Integer onfKey,
        int onfOg,
        String onfName,
        String onfNameExt,
        LocalDate onfStart,
        LocalDate onfEnd
) {
}
