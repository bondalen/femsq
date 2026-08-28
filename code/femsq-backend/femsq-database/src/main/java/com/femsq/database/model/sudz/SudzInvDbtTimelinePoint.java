package com.femsq.database.model.sudz;

import java.time.LocalDate;
import java.util.List;

/**
 * Точка временного ряда долга по слоту invDbt (КСДД, вкладка «Динамика»).
 *
 * @param uplKey ключ выгрузки
 * @param statusDate дата среза ({@code uplStatusOnDate})
 * @param ttl сумма
 * @param overdue просрочка
 * @param source {@code dbtValue} или {@code cnInvDbt}
 * @param varKey invDbtVar
 */
public record SudzInvDbtTimelinePoint(
        Integer uplKey,
        LocalDate statusDate,
        java.math.BigDecimal ttl,
        java.math.BigDecimal overdue,
        String source,
        Integer varKey
) {
}
