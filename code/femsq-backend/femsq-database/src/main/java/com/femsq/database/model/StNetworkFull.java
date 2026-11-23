package com.femsq.database.model;

import java.util.Objects;

/**
 * Полная строка схемы структуры {@code ags.stNet} (type/root).
 */
public record StNetworkFull(
        Integer stnKey,
        Integer stnType,
        String stnName,
        Integer stnRoot
) {
    public StNetworkFull {
        Objects.requireNonNull(stnKey, "stnKey");
        Objects.requireNonNull(stnType, "stnType");
        Objects.requireNonNull(stnName, "stnName");
        Objects.requireNonNull(stnRoot, "stnRoot");
    }
}
