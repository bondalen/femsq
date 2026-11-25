package com.femsq.web.api.dto;

/**
 * DTO листа с резолвом {@code ipgpSh} (§3.2.3).
 */
public record ImpIpgShResolveLeafDto(
        int rowId,
        int rowNo,
        String text,
        String cstAgPnCode,
        Integer resolvedSh,
        String source,
        String errorReason
) {
}
