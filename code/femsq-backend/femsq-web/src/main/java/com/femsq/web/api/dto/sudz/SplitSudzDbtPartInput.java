package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * Одна доля GraphQL Split (S77.3). Деньги — {@code Float} схемы.
 *
 * @param ttl сумма доли
 * @param overd просрочка; null — пропорционально канону
 * @param varKey готовый {@code invDbtVar}; null — клон эталона
 * @param note заметка слота
 * @param dateStart дата образования
 * @param dateMaturity срок
 * @param docBase документ основания
 */
public record SplitSudzDbtPartInput(
        Double ttl,
        Double overd,
        Integer varKey,
        String note,
        LocalDate dateStart,
        LocalDate dateMaturity,
        String docBase
) {
}
