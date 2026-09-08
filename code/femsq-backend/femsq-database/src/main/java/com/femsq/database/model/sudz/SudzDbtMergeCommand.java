package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Команда Merge (S77.3).
 *
 * @param mode каноны или доли на upl
 * @param survivorDbtKey канон-победитель
 * @param slotKeys слоты проигравших канонов ({@code CANONS}) или доли ({@code SHARES_ON_UPL})
 * @param survivorSlotKey слот целой Value при {@code SHARES_ON_UPL}
 * @param uplKey срез при {@code SHARES_ON_UPL}
 */
public record SudzDbtMergeCommand(
        SudzDbtMergeMode mode,
        int survivorDbtKey,
        List<Integer> slotKeys,
        Integer survivorSlotKey,
        Integer uplKey
) {
}
