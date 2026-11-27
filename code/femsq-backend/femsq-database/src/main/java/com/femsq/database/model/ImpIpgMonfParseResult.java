package com.femsq.database.model;

import java.util.List;

/**
 * Итог parse skeleton Monf (C2 §6.5).
 *
 * @param monfKey       ключ {@code impIpgLoadMonf}
 * @param sheetName     лист
 * @param filePath      путь
 * @param codeColumn    1-based колонка кода
 * @param limColumn     1-based колонка лимита
 * @param quarter       режим Q+M
 * @param sumFirst      смещение первой суммы от лимита
 * @param codeHits      найдено маской кода
 * @param loadedCount   строк с lim≠0 (не skipped)
 * @param skippedCount  отсеянных
 * @param rows          staging (включая skipped для прозрачности лога — обычно только loaded)
 * @param logHtml       накопительный HTML
 */
public record ImpIpgMonfParseResult(
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
        List<ImpIpgMonfParseRow> rows,
        String logHtml) {
}
