package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Создание {@code cn_s_org_smpl}.
 */
public record CnSOrgSmplCreateRequest(
        @NotNull Integer csosCnS,
        @NotNull Integer csosOrgId
) {
}
