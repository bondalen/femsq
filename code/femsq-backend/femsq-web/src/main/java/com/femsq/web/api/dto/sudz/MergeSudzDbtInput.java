package com.femsq.web.api.dto.sudz;

import com.femsq.database.model.sudz.SudzDbtMergeMode;
import java.util.List;

/**
 * Вход мутации {@code mergeSudzDbt} (S77.3).
 *
 * @param mode каноны или доли на upl
 * @param survivorDbtKey канон-победитель
 * @param slotKeys слоты проигравших ({@code CANONS}) или доли ({@code SHARES_ON_UPL})
 * @param survivorSlotKey слот целой Value при {@code SHARES_ON_UPL}
 * @param uplKey срез при {@code SHARES_ON_UPL}
 */
public record MergeSudzDbtInput(
        SudzDbtMergeMode mode,
        int survivorDbtKey,
        List<Integer> slotKeys,
        Integer survivorSlotKey,
        Integer uplKey
) {
}
