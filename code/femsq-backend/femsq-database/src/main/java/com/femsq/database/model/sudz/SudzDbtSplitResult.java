package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат Split (S77.3).
 *
 * @param dbtKey канон
 * @param sourceSlotKey исходный слот (история до upl цела)
 * @param uplKey срез долей
 * @param removedSourceValue была ли Value на исходном слоте@upl (снята)
 * @param parts новые слоты/Value
 */
public record SudzDbtSplitResult(
        int dbtKey,
        int sourceSlotKey,
        int uplKey,
        boolean removedSourceValue,
        List<SudzDbtSplitPartResult> parts
) {
}
