package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO превью наследования sti L←S (§3.2.2). В GraphQL отдаются только дыры + счётчики.
 */
public record ImpIpgStiInheritResultDto(
        int loadKey,
        int ipgKey,
        int leafCount,
        int readyCount,
        int holeCount,
        boolean ready,
        List<String> errors,
        List<ImpIpgStiInheritLeafDto> holes
) {
}
