package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Lookup группы комментариев ({@code cnInvCmmGr}).
 *
 * @param cmmGrKey ключ группы
 * @param name имя ({@code cnicgName})
 * @param date дата ({@code cnicgDate})
 */
public record SudzCmmGrLookup(
        int cmmGrKey,
        String name,
        LocalDate date
) {
}
