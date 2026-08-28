package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Временной ряд одного слота invDbt для экрана КСДД.
 *
 * @param idKey слот
 * @param idNum номер слота
 * @param ciaName из idNote или old ciaName
 * @param varKey основной var (мост)
 * @param accnt счёт ГК var
 * @param excelAnchor сумма Excel (якорь)
 * @param excelStatusDate дата среза текущей выгрузки
 * @param points точки ряда
 */
public record SudzInvDbtSlotTimeline(
        int idKey,
        int idNum,
        String ciaName,
        Integer varKey,
        Integer accnt,
        BigDecimal excelAnchor,
        LocalDate excelStatusDate,
        List<SudzInvDbtTimelinePoint> points
) {
}
