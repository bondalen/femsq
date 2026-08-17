package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Обновление {@code cn_s_org_smpl}.
 */
public record CnSOrgSmplUpdateRequest(
        @NotNull Integer csosCnS,
        @NotNull Integer csosOrgId
) {
}
