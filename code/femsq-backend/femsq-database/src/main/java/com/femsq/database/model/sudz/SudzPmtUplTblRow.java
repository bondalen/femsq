package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Строка staging {@code CnInvPmtUplTbl} (Excel→Tbl, Offset A–Z).
 *
 * @param ciputUnloadKey ключ пакета {@code cn_inv_pm_key}
 * @param ciputSheetNum номер листа в книге (1-based)
 */
public record SudzPmtUplTblRow(
        String ciputBE,
        Integer ciputAccount,
        Integer ciputCntrPrtNum,
        String ciputCntrPrtName,
        String ciputCAC,
        Integer ciputAgentNum,
        String ciputAgentName,
        String ciputCnName,
        String ciputLink,
        String ciputCnInv,
        LocalDateTime ciputEntryDate,
        LocalDateTime ciputDocDate,
        LocalDateTime ciputDueDate,
        BigDecimal ciputDbtBlns,
        BigDecimal ciputDbtBlnsOverd,
        BigDecimal ciputDbtBlnsOverdNot,
        BigDecimal ciputCdtBlns,
        BigDecimal ciputCdtBlnsOverd,
        BigDecimal ciputCdtBlnsOverdNot,
        BigDecimal ciputBlns,
        String ciputCnInvDocCode,
        LocalDateTime ciputAlligmentDate,
        LocalDateTime ciputBaseDate,
        BigDecimal ciputCnInvDocSum,
        String ciputStornoReason,
        String ciputStornoDocCode,
        Integer ciputSheetNum,
        int ciputUnloadKey
) {
}
