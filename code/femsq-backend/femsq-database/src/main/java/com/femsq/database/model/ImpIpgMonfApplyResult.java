package com.femsq.database.model;

import java.util.List;

/**
 * Итог apply Monf → UtPlP / LmMn@212 (C2 §6.6).
 *
 * @param monfKey        ключ Monf
 * @param utPlKey        план агента
 * @param ipgKey         ИП
 * @param dryRun         только сверка без записи
 * @param parsedCount    строк staging (loaded)
 * @param appliedCount   записано
 * @param unmatchedCount нет уникального ipgPn
 * @param ambiguousCount >1 ipgPn на код+SmTtl
 * @param errorCount     ошибки записи
 * @param problems       краткие сообщения (сэмпл)
 * @param logHtml        HTML-лог
 */
public record ImpIpgMonfApplyResult(
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
