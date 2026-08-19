package com.femsq.web.api.dto;

import java.time.OffsetDateTime;

/**
 * DTO связи договора и СФ ({@code cnInv}).
 */
public record CnInvDto(
        Integer ciKey,
        Integer ciInv,
        Integer ciCn,
        OffsetDateTime ciTimeOfEntry
) {
}
