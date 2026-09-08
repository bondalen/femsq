package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Одна доля Split (S77.3).
 *
 * @param ttl сумма доли
 * @param overd просрочка; null — пропорционально канону
 * @param varKey готовый {@code invDbtVar}; null — клон var эталонной Value
 * @param note заметка слота
 * @param dateStart дата образования; null — с эталона
 * @param dateMaturity срок; null — с эталона
 * @param docBase документ основания; null — с эталона
 */
public record SudzDbtSplitPart(
        BigDecimal ttl,
        BigDecimal overd,
        Integer varKey,
        String note,
        LocalDate dateStart,
        LocalDate dateMaturity,
        String docBase
) {
}
