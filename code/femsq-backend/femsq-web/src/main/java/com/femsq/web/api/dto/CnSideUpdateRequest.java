package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Обновление {@code cn_s}.
 */
public record CnSideUpdateRequest(
        @NotNull Integer cnKey,
        @NotNull Integer cnSType
) {
}
