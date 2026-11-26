package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO итога сверки ПТСФ.
 */
public record ImpIpgReconcileResultDto(
        int loadKey,
        int stNetKey,
        int matched,
        int open,
        List<ImpIpgReconcileRowDto> rows,
        /** Накопительный HTML-лог «Ход загрузки» (C2 §3.5.4). */
        String logHtml) {
}
