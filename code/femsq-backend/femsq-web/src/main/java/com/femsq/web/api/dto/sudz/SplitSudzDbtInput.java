package com.femsq.web.api.dto.sudz;

import java.util.List;

/**
 * Вход мутации {@code splitSudzDbt} (S77.3).
 *
 * @param dbtKey канон
 * @param sourceSlotKey слот с целой историей
 * @param uplKey срез долей
 * @param parts доли (сумма ttl = канон)
 */
public record SplitSudzDbtInput(
        int dbtKey,
        int sourceSlotKey,
        int uplKey,
        List<SplitSudzDbtPartInput> parts
) {
}
