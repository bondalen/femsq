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
        int totalRows) {
}
