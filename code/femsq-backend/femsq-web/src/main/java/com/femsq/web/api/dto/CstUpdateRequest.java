package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

/**
 * Запрос на обновление стройки.
 */
public record CstUpdateRequest(
        @NotBlank String cstName,
        String cstBusSgm,
        UUID cstOidOld,
        Integer cstMark
) {
}
