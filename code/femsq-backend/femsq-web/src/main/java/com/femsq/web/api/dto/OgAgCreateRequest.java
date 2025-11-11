package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Запрос на создание агентской организации.
 */
public record OgAgCreateRequest(
        @NotBlank(message = "code обязателен")
        @Size(max = 255, message = "code не должен превышать 255 символов")
        String code,

        @NotNull(message = "organizationKey обязателен")
        Integer organizationKey,

        UUID legacyOid
) {
}
