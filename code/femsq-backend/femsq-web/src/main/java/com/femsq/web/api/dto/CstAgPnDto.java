package com.femsq.web.api.dto;

import java.util.UUID;

/**
 * DTO САК {@code ags.cstAgPn}.
 */
public record CstAgPnDto(
        Integer cstapKey,
        Integer cstapCsta,
        String cstapIpgPnN,
        UUID cstapOidOld
) {
}
