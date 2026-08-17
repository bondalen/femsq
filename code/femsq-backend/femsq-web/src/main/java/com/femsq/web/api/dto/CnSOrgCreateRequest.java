package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Создание {@code cn_s_org}.
 */
public record CnSOrgCreateRequest(
        @NotNull Integer csoCnSOrgSmpl,
        LocalDate dateBeg,
        LocalDate dateEnd,
        String csoAsbuId,
        LocalDate csoCnDate
) {
}
