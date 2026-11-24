package com.femsq.web.api.dto;

/**
 * DTO строки staging {@code ags.impIpg}.
 */
public record ImpIpgRowDto(
        int id,
        int loadKey,
        int rowNo,
        String rowKind,
        String text,
        Integer parentKey,
        Integer stiKey,
        String ctx) {
}
