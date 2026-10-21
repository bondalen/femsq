package com.femsq.database.model.sudz;

/**
 * Строка словаря FIO ({@code ags.fioDict}) для краткого отчёта.
 *
 * @param fioDictKey PK
 * @param fdName имя (осн.)
 * @param fdNameF парное/жен. имя
 * @param fdPatrM отчество муж.
 * @param fdPatrM2 вариант отчества муж.
 * @param fdPatrF2 вариант отчества жен.
 * @param fdPatrF отчество жен.
 */
public record SudzFioDict(
        int fioDictKey,
        String fdName,
        String fdNameF,
        String fdPatrM,
        String fdPatrM2,
        String fdPatrF2,
        String fdPatrF
) {
}
