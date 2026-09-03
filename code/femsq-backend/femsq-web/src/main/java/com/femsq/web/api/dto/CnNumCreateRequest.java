package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Добавление номера к существующему договору ({@code ags.cnNum}).
 */
public record CnNumCreateRequest(
        @NotNull Integer cnKey,
        String cnnNum,
        @NotNull Integer cnnType,
        String note
) {
}
