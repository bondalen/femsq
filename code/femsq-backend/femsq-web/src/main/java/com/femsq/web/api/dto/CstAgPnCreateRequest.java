package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Запрос на создание САК.
 */
public record CstAgPnCreateRequest(
        @NotNull Integer cstapCsta,
        @NotBlank String cstapIpgPnN,
        UUID cstapOidOld
) {
}
