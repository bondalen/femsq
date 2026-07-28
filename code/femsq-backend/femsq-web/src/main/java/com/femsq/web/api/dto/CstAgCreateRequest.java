package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Запрос на создание агента на стройке.
 */
public record CstAgCreateRequest(
        @NotNull Integer cstaAg,
        @NotNull Integer cstaCst,
        UUID cstaOidOld,
        Integer cstaInvestor
) {
}
