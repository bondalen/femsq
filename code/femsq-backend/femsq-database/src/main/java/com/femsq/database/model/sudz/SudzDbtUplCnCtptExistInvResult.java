package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Итог подготовки шага {@code CnCtptExistInvNotLoad} (буфер + лог).
 *
 * @param invoiceRowCount строк в {@code CnInvDbtUplTblCnInv}
 * @param contracts договоры для HTML-лога
 */
public record SudzDbtUplCnCtptExistInvResult(
        int invoiceRowCount,
        List<SudzDbtUplCnCtptExistInvContract> contracts
) {
    /**
     * Компактный конструктор: неизменяемый список.
     */
    public SudzDbtUplCnCtptExistInvResult {
        contracts = List.copyOf(contracts);
    }
}
