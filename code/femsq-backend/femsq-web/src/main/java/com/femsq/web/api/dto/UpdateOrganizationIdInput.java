package com.femsq.web.api.dto;

/**
 * Обновление строки {@code org_id}.
 *
 * @param orgIdKey PK
 * @param org ogKey
 * @param orgIdType 1/2
 * @param orgIdValueL цифровой ключ
 * @param orgIdValueT текстовый ключ
 * @param orgIdValueTExt расширение (КПП)
 */
public record UpdateOrganizationIdInput(
        int orgIdKey,
        int org,
        int orgIdType,
        Integer orgIdValueL,
        String orgIdValueT,
        String orgIdValueTExt
) {
}
