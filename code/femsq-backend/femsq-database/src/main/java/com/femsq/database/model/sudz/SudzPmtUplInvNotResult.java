package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Итог подготовки шага {@code cipuCn_CtptCnOneInvNotLoad} (буфер TblCnInv + лог).
 *
 * @param invoiceRowCount строк в {@code CnInvPmtUplTblCnInv}
 * @param contracts договоры для HTML-лога
 */
public record SudzPmtUplInvNotResult(
        int invoiceRowCount,
        List<SudzPmtUplInvNotContract> contracts
) {
    /**
     * Компактный конструктор: неизменяемый список.
     */
    public SudzPmtUplInvNotResult {
        contracts = List.copyOf(contracts);
    }
}
