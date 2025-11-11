package com.femsq.database.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Представляет агентскую организацию (таблица {@code ags_test.ogAg}) для DAO-слоя.
 *
 * @param ogAgKey   идентификатор записи (PRIMARY KEY)
 * @param code      код агентской организации
 * @param organizationKey ссылка на основную организацию ({@code ags_test.og.ogKey})
 * @param legacyOid идентификатор из устаревшей системы (может отсутствовать)
 */
public record OgAg(
        Integer ogAgKey,
        String code,
        Integer organizationKey,
        UUID legacyOid
) {

    public OgAg {
        Objects.requireNonNull(code, "code");
        Objects.requireNonNull(organizationKey, "organizationKey");
    }
}
