package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Запрос на обновление САК.
 */
public record CstAgPnUpdateRequest(
        @NotNull Integer cstapCsta,
        @NotBlank String cstapIpgPnN,
        UUID cstapOidOld
) {
}
