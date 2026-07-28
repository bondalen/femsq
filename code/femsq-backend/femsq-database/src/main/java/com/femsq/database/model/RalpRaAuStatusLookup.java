package com.femsq.database.model;

import java.util.Objects;

/**
 * Lookup статуса строки {@code ralpRaAu} (Access {@code ralpRaAuStatus}; в SQL Server таблицы нет).
 *
 * @param code  код 0..3
 * @param label подпись
 */
public record RalpRaAuStatusLookup(int code, String label) {

    public RalpRaAuStatusLookup {
        Objects.requireNonNull(label, "label");
    }
}
