package com.femsq.database.model;

import java.util.Objects;

/**
 * Lookup периода отчёта ({@code ags.ra_period}).
 *
 * @param key ключ периода
 * @param p   текстовая подпись периода
 */
public record RaPeriodLookup(Integer key, String p) {

    public RaPeriodLookup {
        Objects.requireNonNull(key, "key");
        Objects.requireNonNull(p, "p");
    }
}
