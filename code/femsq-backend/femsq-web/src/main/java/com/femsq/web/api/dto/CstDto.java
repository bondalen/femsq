package com.femsq.web.api.dto;

import java.util.UUID;

/**
 * DTO стройки {@code ags.cst}.
 */
public record CstDto(
        Integer cstKey,
        String cstName,
        String cstBusSgm,
        UUID cstOidOld,
        Integer cstMark
) {
}
