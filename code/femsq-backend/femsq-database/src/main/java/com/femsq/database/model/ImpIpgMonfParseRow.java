package com.femsq.database.model;

import java.math.BigDecimal;
import java.util.List;

/**
 * Строка staging разбора Monf (C2 §6.5): код + limYear + Q/M.
 *
 * @param rowNo     номер Excel-строки (1-based)
 * @param cstCode   код {@code NNN-NNNNNNN}
 * @param name      имя справа от кода
 * @param limYear   годовой лимит (млн), scale 8
 * @param quarters  Q1..Q4 (nullable элементы, если quarter=false — пусто)
 * @param months    M01..M12
 * @param skipped   true = отсев (направление затрат / zero lim)
 * @param skipReason причина отсева или null
 */
public record ImpIpgMonfParseRow(
        int rowNo,
        String cstCode,
        String name,
        BigDecimal limYear,
        List<BigDecimal> quarters,
        List<BigDecimal> months,
        boolean skipped,
        String skipReason) {
}
