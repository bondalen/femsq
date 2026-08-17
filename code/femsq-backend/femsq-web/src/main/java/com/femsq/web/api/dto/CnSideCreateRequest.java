package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Создание {@code cn_s}.
 */
public record CnSideCreateRequest(
        @NotNull Integer cnKey,
        @NotNull Integer cnSType
) {
}
