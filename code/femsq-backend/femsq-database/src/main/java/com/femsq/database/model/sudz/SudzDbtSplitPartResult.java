package com.femsq.database.model.sudz;

/**
 * Созданная доля Split.
 *
 * @param slotKey {@code invDbt.idKey}
 * @param varKey {@code invDbtVar}
 * @param valueKey {@code DbtValue.dvKey}
 * @param ttl сумма
 */
public record SudzDbtSplitPartResult(
        int slotKey,
        int varKey,
        int valueKey,
        java.math.BigDecimal ttl
) {
}
