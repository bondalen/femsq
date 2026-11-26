package com.femsq.web.api.dto;

/**
 * DTO итога парсера Excel → {@code impIpg}.
 */
public record ImpIpgParseResultDto(
        int loadKey,
        String sheetName,
        String filePath,
        int sectionCount,
        int leafCount,
        int totalRows,
        /** Накопительный HTML-лог «Ход загрузки» (C2 §3.5.4). */
        String logHtml) {
}
