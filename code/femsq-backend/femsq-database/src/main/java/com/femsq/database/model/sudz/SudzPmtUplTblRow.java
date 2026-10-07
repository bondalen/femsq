package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Строка staging {@code CnInvPmtUplTbl} (Excel→Tbl).
 * <p>
 * Ключи {@code ciputSfKey} / {@code ciputCacSpanKey} / {@code ciputDueKey} /
 * {@code ciputDueGrp} заполняются только для традиционной раскладки
 * (outline 3/4); иначе {@code null}.
 * </p>
 *
 * @param ciputUnloadKey ключ пакета {@code cn_inv_pm_key}
 * @param ciputSheetNum номер листа в книге (1-based)
 * @param ciputSfKey суррогат СФ файла в пределах пакета
 * @param ciputCacSpanKey суррогат сплошного отрезка стройки
 * @param ciputDueKey суррогат жёлтого итога срока
 * @param ciputDueGrp порядковый номер жёлтой группы внутри СФ+CAC+срок (1…n)
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
        int ciputUnloadKey,
        Integer ciputSfKey,
        Integer ciputCacSpanKey,
        Integer ciputDueKey,
        Integer ciputDueGrp
) {
}
