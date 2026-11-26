package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO итога bulk apply пунктов (§3.2.4).
 */
public record ImpIpgPointsApplyResultDto(
        int loadKey,
        int ipgKey,
        Integer previousIpgKey,
        boolean dryRun,
        int leafCount,
        int appliedCount,
        int skippedAlreadyCount,
        boolean ready,
        List<String> errors,
        List<Integer> problemRowIds,
        List<Integer> createdPnKeys,
        /** Накопительный HTML-лог «Ход загрузки» (C2 §3.5.4). */
        String logHtml
) {
}
