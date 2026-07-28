package com.femsq.database.model;

import java.util.Objects;

/**
 * Lookup агента для combo (представление {@code ags.ogAgCs}).
 *
 * @param ogaKey идентификатор агента
 * @param ogaNm  подпись «код + имя»
 */
public record OgAgCs(
        Integer ogaKey,
        String ogaNm
) {

    public OgAgCs {
        Objects.requireNonNull(ogaKey, "ogaKey");
        Objects.requireNonNull(ogaNm, "ogaNm");
    }
}
