package com.femsq.web.api.dto;

/**
 * DTO листа с резолвом sti L←S (§3.2.2).
 */
public record ImpIpgStiInheritLeafDto(
        int rowId,
        int rowNo,
        String text,
        Integer parentKey,
        Integer resolvedStiKey,
        String holeReason
) {
}
