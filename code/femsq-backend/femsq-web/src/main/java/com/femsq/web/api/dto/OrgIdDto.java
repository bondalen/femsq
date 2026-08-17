package com.femsq.web.api.dto;

/**
 * DTO строки {@code ags.org_id}.
 *
 * @param orgIdKey PK
 * @param org FK → og
 * @param orgIdType 1=БУиРГ, 2=ИНН
 * @param orgIdValueL БУиРГ
 * @param orgIdValueT ИНН
 * @param orgIdValueTExt расширение
 */
public record OrgIdDto(
        Integer orgIdKey,
        int org,
        int orgIdType,
        Integer orgIdValueL,
        String orgIdValueT,
        String orgIdValueTExt
) {
}
