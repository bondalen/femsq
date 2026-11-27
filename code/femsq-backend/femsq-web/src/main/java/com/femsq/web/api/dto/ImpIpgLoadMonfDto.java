package com.femsq.web.api.dto;

/**
 * DTO строки {@code ags.impIpgLoadMonf} (C2 §6).
 */
public record ImpIpgLoadMonfDto(
        int id,
        int loadKey,
        Integer utPlKey,
        String name,
        String filePath,
        String sheet,
        String limColumn,
        boolean quarter,
        Integer sumFirst,
        String note,
        /** ISO-8601 local datetime или null. */
        String created,
        /** HTML-лог разбора/применения. */
        String logHtml) {
}
