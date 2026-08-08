package com.femsq.database.model.sudz;

/**
 * Lookup календарного года ({@code ags.yyyy}).
 *
 * @param yKey ключ
 * @param yyyy календарный год
 */
public record SudzYyyyLookup(
        int yKey,
        int yyyy
) {
}
