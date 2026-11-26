package com.femsq.database.model;

/**
 * Итог разбора Excel годовой ИП в staging ({@code impIpg}).
 * {@code logHtml} — накопительный лог «Ход загрузки» (C2 §3.5.4), nullable.
 */
public record ImpIpgParseResult(
        int loadKey,
        String sheetName,
        String filePath,
        int sectionCount,
        int leafCount,
        int totalRows,
        String logHtml) {

    /** Конструктор без лога ({@code logHtml = null}). */
    public ImpIpgParseResult(
            int loadKey,
            String sheetName,
            String filePath,
            int sectionCount,
            int leafCount,
            int totalRows) {
        this(loadKey, sheetName, filePath, sectionCount, leafCount, totalRows, null);
    }
}
