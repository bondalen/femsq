package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Создание связи {@code cnInv} между существующими договором и СФ.
 */
public record CnInvCreateRequest(
        @NotNull Integer ciInv,
        @NotNull Integer ciCn
) {
}
