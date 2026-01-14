package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

/**
 * Запрос на создание новой ревизии.
 */
public record RaACreateRequest(
        @NotBlank(message = "adtName обязателен")
        @Size(max = 255, message = "adtName не должен превышать 255 символов")
        String adtName,

        LocalDateTime adtDate,

        String adtResults,

        @NotNull(message = "adtDir обязателен")
        Integer adtDir,

        @NotNull(message = "adtType обязателен")
        Integer adtType,

        @NotNull(message = "adtAddRA обязателен")
        Boolean adtAddRA
) {
}