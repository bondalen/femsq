package com.femsq.web.api.dto;

import java.util.UUID;

/**
 * DTO представление агентской организации {@code ags_test.ogAg}.
 *
 * @param ogAgKey         идентификатор агентской организации
 * @param code            код агентской организации
 * @param organizationKey идентификатор базовой организации
 * @param legacyOid       идентификатор устаревшей системы
 */
public record OgAgDto(
        Integer ogAgKey,
        String code,
        Integer organizationKey,
        UUID legacyOid
) {
}
