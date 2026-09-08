package com.femsq.database.model;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Objects;

/**
 * Договор ({@code ags.cn}).
 *
 * @param cnKey         PK ({@code cn_key})
 * @param cnNumber      номер ({@code cn_number})
 * @param cnDate        справочная дата договора
 * @param cnNote        примечание (может быть HTML)
 * @param cnMark        служебная метка (воронка и пр.)
 * @param cnTimeOfEntry время ввода записи (аудит, read-only в UI)
 * @param cnName        отображаемое имя ({@code cnName})
 */
public record Cn(
        Integer cnKey,
        String cnNumber,
        LocalDate cnDate,
        String cnNote,
        Integer cnMark,
        OffsetDateTime cnTimeOfEntry,
        String cnName
) {

    public Cn {
        Objects.requireNonNull(cnKey, "cnKey");
    }
}
