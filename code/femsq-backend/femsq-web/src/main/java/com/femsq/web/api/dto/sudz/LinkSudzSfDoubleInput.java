package com.femsq.web.api.dto.sudz;

import jakarta.validation.constraints.NotNull;

/**
 * Привязка строки КСДСФ к существующему договору через {@code ags.cnInv}.
 */
public record LinkSudzSfDoubleInput(
        @NotNull Integer ciusKey,
        @NotNull Integer invKey,
        @NotNull Integer cnKey
) {
}
