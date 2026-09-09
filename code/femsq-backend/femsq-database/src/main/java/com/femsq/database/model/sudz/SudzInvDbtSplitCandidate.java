package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.util.List;

/**
 * Кандидат Split для советника КСДД (S77.4): N строк свода, сумма = Value слота.
 *
 * @param dbtKey канон
 * @param sourceSlotKey слот с целой историей
 * @param uplKey срез долей
 * @param sourceTtl сумма канона на срезе / последняя история
 * @param parts доли из открытых строк очереди
 */
public record SudzInvDbtSplitCandidate(
        int dbtKey,
        int sourceSlotKey,
        int uplKey,
        BigDecimal sourceTtl,
        List<SudzDbtSplitPart> parts
) {
}
