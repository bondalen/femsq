package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Запрос на обновление существующего файла для проверки.
 */
public record RaFUpdateRequest(
        @NotBlank(message = "afName обязателен")
        @Size(max = 500, message = "afName не должен превышать 500 символов")
        String afName,

        @NotNull(message = "afDir обязателен")
        Integer afDir,

        @NotNull(message = "afType обязателен")
        Integer afType,

        @NotNull(message = "afExecute обязателен")
        Boolean afExecute,

        Boolean afSource,

        Integer raOrgSender,

        Integer afNum
) {
}
