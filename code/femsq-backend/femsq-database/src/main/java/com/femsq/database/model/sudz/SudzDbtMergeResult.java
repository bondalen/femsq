package com.femsq.database.model.sudz;

/**
 * Результат Merge (S77.3).
 *
 * @param survivorDbtKey канон-победитель
 * @param mode режим
 * @param updatedBridges сколько мостов {@code invDbtDbt} переписано
 * @param removedShareValues сколько Value долей снято с upl
 * @param restoredValueKey {@code dvKey} целой Value при {@code SHARES_ON_UPL}; иначе null
 */
public record SudzDbtMergeResult(
        int survivorDbtKey,
        SudzDbtMergeMode mode,
        int updatedBridges,
        int removedShareValues,
        Integer restoredValueKey
) {
}
