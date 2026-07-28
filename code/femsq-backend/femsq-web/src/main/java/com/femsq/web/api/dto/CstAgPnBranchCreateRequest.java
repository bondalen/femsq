package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Запрос на создание филиала САК.
 */
public record CstAgPnBranchCreateRequest(
        @NotNull Integer cstapbCstAgPn,
        @NotNull Integer cstapbBranch,
        LocalDate cstapbStart,
        LocalDate cstapbEnd
) {
}
