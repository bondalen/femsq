package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Запрос на обновление филиала САК.
 */
public record CstAgPnBranchUpdateRequest(
        @NotNull Integer cstapbCstAgPn,
        @NotNull Integer cstapbBranch,
        LocalDate cstapbStart,
        LocalDate cstapbEnd
) {
}
