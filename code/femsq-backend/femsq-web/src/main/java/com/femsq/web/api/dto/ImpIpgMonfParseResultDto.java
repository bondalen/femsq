package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO итога parse Monf (§6.5).
 */
public record ImpIpgMonfParseResultDto(
        int monfKey,
        String sheetName,
        String filePath,
        int codeColumn,
        int limColumn,
        boolean quarter,
        int sumFirst,
        int codeHits,
        int loadedCount,
        int skippedCount,
        List<ImpIpgMonfParseRowDto> rows,
        String logHtml) {
}
