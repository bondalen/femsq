package com.femsq.database.model;

/**
 * Идентификатор организации в {@code ags.org_id}.
 * type=1 — код БУиРГ ({@code org_id_value_l}); type=2 — ИНН ({@code org_id_value_t}).
 *
 * @param orgIdKey PK
 * @param org FK → {@code og.ogKey}
 * @param orgIdType 1 или 2
 * @param orgIdValueL числовое значение (БУиРГ)
 * @param orgIdValueT текстовое значение (ИНН)
 * @param orgIdValueTExt расширение (КПП и т.п.), nullable
 */
public record OrgId(
        Integer orgIdKey,
        int org,
        int orgIdType,
        Integer orgIdValueL,
        String orgIdValueT,
        String orgIdValueTExt
) {
    /** Тип: код БУиРГ. */
    public static final int TYPE_BUIRG = 1;

    /** Тип: ИНН. */
    public static final int TYPE_ITN = 2;
}
