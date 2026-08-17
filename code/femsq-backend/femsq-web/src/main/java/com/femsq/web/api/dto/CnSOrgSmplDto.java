package com.femsq.web.api.dto;

import java.util.List;

/**
 * {@code cn_s_org_smpl} с вложенными {@code cn_s_org}.
 */
public record CnSOrgSmplDto(
        Integer csosKey,
        Integer csosCnS,
        Integer csosOrgId,
        String orgLabel,
        String csosTimeOfEntry,
        List<CnSOrgDto> orgs
) {
}
