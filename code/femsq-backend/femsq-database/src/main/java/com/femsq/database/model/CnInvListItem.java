package com.femsq.database.model;

import java.time.OffsetDateTime;

/**
 * Строка page-списка связей договора↔СФ ({@code cnInv} + {@code inv.iNum}).
 */
public record CnInvListItem(
        Integer ciKey,
        int ciInv,
        int ciCn,
        OffsetDateTime ciTimeOfEntry,
        String iNum
) {
}
