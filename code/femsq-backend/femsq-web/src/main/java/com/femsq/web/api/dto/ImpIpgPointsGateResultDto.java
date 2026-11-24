package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO gate загрузки пунктов (§3.2.1).
 */
public record ImpIpgPointsGateResultDto(
        int loadKey,
        int ipgKey,
        Integer stNetKey,
        int sectionCount,
        int openCount,
        boolean ready,
        List<String> errors,
        List<Integer> openRowIds
) {
}
