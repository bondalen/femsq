package com.femsq.database.model;

import java.time.LocalDateTime;

/**
 * Строка помесячного Excel агента ({@code ags.impIpgLoadMonf}), C2 §6.
 *
 * @param iilmKey       PK
 * @param iilmLoad      сессия {@code impIpgLoad}
 * @param iilmUtPl      целевой план (nullable)
 * @param iilmNm        имя
 * @param iilmFilePath  путь к Excel
 * @param iilmSheet     лист
 * @param iilmLimColumn якорь Find колонки лимита
 * @param iilmQuarter   true = Q+M (16), false = 12 M
 * @param iilmSumFirst  смещение первой суммы
 * @param iilmNote      заметка
 * @param iilmCreated   создано
 * @param iilmResults   HTML-лог
 */
public record ImpIpgLoadMonf(
        int iilmKey,
        int iilmLoad,
        Integer iilmUtPl,
        String iilmNm,
        String iilmFilePath,
        String iilmSheet,
        String iilmLimColumn,
        boolean iilmQuarter,
        Integer iilmSumFirst,
        String iilmNote,
        LocalDateTime iilmCreated,
        String iilmResults
) {
}
