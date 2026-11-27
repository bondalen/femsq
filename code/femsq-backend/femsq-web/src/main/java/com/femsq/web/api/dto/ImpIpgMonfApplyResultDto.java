package com.femsq.web.api.dto;

import java.util.List;

/**
 * DTO итога apply Monf (§6.6).
 */
public record ImpIpgMonfApplyResultDto(
        int monfKey,
        int utPlKey,
        int ipgKey,
        boolean dryRun,
        int parsedCount,
        int appliedCount,
        int unmatchedCount,
        int ambiguousCount,
        int errorCount,
        List<String> problems,
        String logHtml) {
}
