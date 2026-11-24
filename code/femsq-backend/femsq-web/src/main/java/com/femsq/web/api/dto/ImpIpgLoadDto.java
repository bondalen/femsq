package com.femsq.web.api.dto;

/**
 * DTO сессии загрузки {@code ags.impIpgLoad}.
 */
public record ImpIpgLoadDto(
        int id,
        int ipgKey,
        String name,
        String filePath,
        String note,
        /** ISO-8601 local datetime или null. */
        String created) {
}
