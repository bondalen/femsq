package com.femsq.database.model;

import java.math.BigDecimal;

/**
 * Черновик пункта + sti для bulk apply (§3.2.4).
 */
public record IpgPnBulkDraft(
        int stagingRowId,
        Integer ipgpNum,
        int cstAgPnKey,
        int ipgpSh,
        BigDecimal ipgpSmTtl,
        BigDecimal ipgpSmWrk,
        BigDecimal ipgpSmEqu,
        BigDecimal ipgpSmOth,
        String ipgpTskCms,
        int stiKey
) {
}
