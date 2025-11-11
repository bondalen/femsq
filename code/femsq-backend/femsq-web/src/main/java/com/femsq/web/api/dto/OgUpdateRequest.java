package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Запрос на обновление существующей организации.
 */
public record OgUpdateRequest(
        @NotBlank(message = "ogName обязателен")
        @Size(max = 255, message = "ogName не должен превышать 255 символов")
        String ogName,

        @NotBlank(message = "ogOfficialName обязателен")
        @Size(max = 255, message = "ogOfficialName не должен превышать 255 символов")
        String ogOfficialName,

        @Size(max = 255, message = "ogFullName не должен превышать 255 символов")
        String ogFullName,

        @Size(max = 1000, message = "ogDescription не должен превышать 1000 символов")
        String ogDescription,

        Double inn,
        Double kpp,
        Double ogrn,
        Double okpo,
        Integer oe,

        @NotNull(message = "registrationTaxType обязателен")
        @Pattern(regexp = "(?i)og|sd|ie", message = "Поддерживаются значения og, sd или ie")
        String registrationTaxType
) {
}
