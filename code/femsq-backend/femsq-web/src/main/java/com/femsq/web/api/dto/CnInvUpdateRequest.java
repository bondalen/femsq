package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Правка связи {@code cnInv}: допускается менять привязанный договор или СФ.
 */
public record CnInvUpdateRequest(
        @NotNull Integer ciInv,
        @NotNull Integer ciCn
) {
}
