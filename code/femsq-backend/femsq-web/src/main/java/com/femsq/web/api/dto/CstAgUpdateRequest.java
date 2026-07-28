package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Запрос на обновление агента на стройке.
 */
public record CstAgUpdateRequest(
        @NotNull Integer cstaAg,
        @NotNull Integer cstaCst,
        UUID cstaOidOld,
        Integer cstaInvestor
) {
}
