package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Команда Split канона на доли одной upl (S77.3). История предыдущих upl не режется.
 *
 * @param dbtKey канон
 * @param sourceSlotKey слот с целой историей
 * @param uplKey срез, на котором появляются доли
 * @param parts доли (сумма ttl = канон)
 */
public record SudzDbtSplitCommand(
        int dbtKey,
        int sourceSlotKey,
        int uplKey,
        List<SudzDbtSplitPart> parts
) {
}
