package com.femsq.database.model;

/**
 * Lookup {@code org_id} (type=1 БУиРГ) для выбора {@code csosOrgId}.
 *
 * @param orgIdKey {@code org_id_key}
 * @param buirg код БУиРГ
 * @param label подпись для select
 */
public record CnSOrgIdLookup(
        int orgIdKey,
        Integer buirg,
        String label
) {
}
