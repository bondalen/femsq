package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет структуру сети (таблица {@code ags.stNet}).
 */
public record StNetwork(
        Integer stnKey,
        String name
) {
    public StNetwork {
        Objects.requireNonNull(stnKey, "stnKey");
        Objects.requireNonNull(name, "name");
    }
}
