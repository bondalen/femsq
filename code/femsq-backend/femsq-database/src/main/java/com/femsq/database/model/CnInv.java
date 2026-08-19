package com.femsq.database.model;

import java.time.OffsetDateTime;

/**
 * Связь договора и счёта-фактуры ({@code ags.cnInv}).
 */
public record CnInv(
        Integer ciKey,
        int ciInv,
        int ciCn,
        OffsetDateTime ciTimeOfEntry
) {
}
