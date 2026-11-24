package com.femsq.database.model;

/**
 * Итог разбора Excel годовой ИП в staging ({@code impIpg}).
 */
public record ImpIpgParseResult(
        int loadKey,
        String sheetName,
        String filePath,
        int sectionCount,
        int leafCount,
        int totalRows) {
}
