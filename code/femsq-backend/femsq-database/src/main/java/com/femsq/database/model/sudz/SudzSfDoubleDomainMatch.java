package com.femsq.database.model.sudz;

import java.time.OffsetDateTime;

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
 * @param cntrPrtNum первый БУиРГ исполнителя (type=2); может быть null
 * @param cntrPrtName склейка исполнителей {@code «БУиРГ · имя; …»}; может быть null
 */
public record SudzSfDoubleDomainMatch(
        int invKey,
        String invNum,
        Integer invNumKey,
        OffsetDateTime invEntered,
        Integer ciKey,
        Integer cnKey,
        String cnNum,
        Integer cntrPrtNum,
        String cntrPrtName
) {
}
