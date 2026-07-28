package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

/**
 * Запрос на создание стройки.
 */
public record CstCreateRequest(
        @NotBlank String cstName,
        String cstBusSgm,
        UUID cstOidOld,
        Integer cstMark
) {
}
