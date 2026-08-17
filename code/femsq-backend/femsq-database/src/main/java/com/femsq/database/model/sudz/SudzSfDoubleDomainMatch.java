package com.femsq.database.model.sudz;

import java.time.LocalDateTime;

/**
 * Существующий СФ в домене с номером, совпадающим с кандидатом КСДСФ.
 *
 * @param invKey {@code ags.inv.iKey}
 * @param invNum номер
 * @param invNumKey {@code invNum.inKey}
 * @param invEntered время ввода inv
 * @param ciKey связь cnInv (может быть несколько — одна строка на связь)
 * @param cnKey договор
 * @param cnNum номер договора (если есть)
 */
public record SudzSfDoubleDomainMatch(
        int invKey,
        String invNum,
        Integer invNumKey,
        LocalDateTime invEntered,
        Integer ciKey,
        Integer cnKey,
        String cnNum
) {
}
