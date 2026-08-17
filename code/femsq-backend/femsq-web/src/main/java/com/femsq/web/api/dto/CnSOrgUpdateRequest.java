package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Обновление {@code cn_s_org}.
 */
public record CnSOrgUpdateRequest(
        @NotNull Integer csoCnSOrgSmpl,
        LocalDate dateBeg,
        LocalDate dateEnd,
        String csoAsbuId,
        LocalDate csoCnDate
) {
}
