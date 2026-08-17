package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Строка буфера Excel → {@code CnInvDbtUplTbl} (шаг {@code excelToTbl}).
 *
 * @param findDbtNum порядковый номер найденной задолженности
 * @param cidutAccount ключ счёта ({@code FileSh.cidufsAccount})
 * @param cidutCntrPrtNum № контрагента (БУиРГ)
 * @param cidutCntrPrtName наименование контрагента
 * @param cidutCntrPrtITN ИНН
 * @param cidutCnName договор
 * @param cidutCnDate дата договора
 * @param cidutCnInv документ основания (СФ)
 * @param cidutFormtnDate дата образования
 * @param cidutMatrtyDate срок погашения
 * @param cidutDebt сумма задолженности
 * @param cidutDebtOverdue просроченная задолженность
 * @param cidutDoc документ основания (присвоение ГК)
 * @param cidutLink ссылка
 * @param cidutSheet ключ листа FileSh
 * @param cidutSheetNum порядковый номер строки на листе
 * @param cidutUnloadKey {@code upl_key}
 */
public record SudzDbtUplTblRow(
        int findDbtNum,
        int cidutAccount,
        Integer cidutCntrPrtNum,
        String cidutCntrPrtName,
        String cidutCntrPrtITN,
        String cidutCnName,
        LocalDateTime cidutCnDate,
        String cidutCnInv,
        LocalDateTime cidutFormtnDate,
        LocalDateTime cidutMatrtyDate,
        BigDecimal cidutDebt,
        BigDecimal cidutDebtOverdue,
        String cidutDoc,
        String cidutLink,
        int cidutSheet,
        int cidutSheetNum,
        int cidutUnloadKey
) {
}
