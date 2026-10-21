package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input создания строки {@code ags.fioDict}.
 *
 * @param fdName имя (осн.)
 * @param fdNameF парное/жен. имя
 * @param fdPatrM отчество муж.
 * @param fdPatrM2 вариант отчества муж.
 * @param fdPatrF2 вариант отчества жен.
 * @param fdPatrF отчество жен.
 */
public record CreateSudzFioDictInput(
        String fdName,
        String fdNameF,
        String fdPatrM,
        String fdPatrM2,
        String fdPatrF2,
        String fdPatrF
) {
}
