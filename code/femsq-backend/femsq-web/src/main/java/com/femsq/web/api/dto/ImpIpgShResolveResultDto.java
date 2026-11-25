package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO превью резолва {@code ipgpSh} (§3.2.3). В GraphQL — счётчики + проблемные листья.
 */
public record ImpIpgShResolveResultDto(
        int loadKey,
        int ipgKey,
        Integer previousIpgKey,
        int leafCount,
        int resolvedCount,
        int errorCount,
        int fromPrevCount,
        int default4Count,
        int freePoolCount,
        boolean ready,
        List<String> errors,
        List<ImpIpgShResolveLeafDto> problemLeaves
) {
}
