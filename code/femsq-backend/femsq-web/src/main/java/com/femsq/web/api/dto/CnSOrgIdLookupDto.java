package com.femsq.web.api.dto;

/**
 * Lookup {@code org_id} type=1 для {@code csosOrgId}.
 */
public record CnSOrgIdLookupDto(
        Integer orgIdKey,
        Integer buirg,
        String label
) {
}
