package com.femsq.database.model;

import java.time.LocalDate;
import java.util.Objects;

/**
 * Договор ({@code ags.cn}).
 *
 * @param cnKey    PK ({@code cn_key})
 * @param cnNumber номер ({@code cn_number})
 * @param cnDate   дата
 * @param cnNote   примечание (может быть HTML)
 * @param cnMark   служебная метка
 */
public record Cn(
        Integer cnKey,
        String cnNumber,
        LocalDate cnDate,
        String cnNote,
        Integer cnMark
) {

    public Cn {
        Objects.requireNonNull(cnKey, "cnKey");
    }
}
