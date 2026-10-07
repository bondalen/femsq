package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Карточка Excel-кандидата КСДСФ: свод ({@code CnInvDbtUplTbl}) или платежи ({@code CnInvPmtUplTbl}).
 * Поле {@code source}: {@code dbt} | {@code pmt}. Для pmt ключ строки в {@code cidutKey} (= ciputKey);
 * {@code cidutDebt}/{@code cidutDebtOverdue} — только долг свода (для pmt null).
 *
 * @param cidutKey ключ Tbl (cidut или ciput)
 * @param findDbtNum FindDbtNum (только dbt)
 * @param cidutAccount счёт (ключ или номер — зависит от join)
 * @param cidutAccntNum номер счёта ГК
 * @param cidutCntrPrtNum БУиРГ
 * @param cidutCntrPrtName имя контрагента
 * @param cidutCntrPrtITN ИНН
 * @param cidutCnName договор (текст Excel)
 * @param cidutCnDate дата договора (dbt)
 * @param cidutCnInv номер СФ
 * @param cidutCnInvName имя СФ (dbt)
 * @param cidutFormtnDate дата обр. (dbt) / проводки (pmt)
 * @param cidutMatrtyDate дата погаш. (dbt) / срока (pmt)
 * @param cidutDebt долг (только dbt)
 * @param cidutDebtOverdue просрочка долга (только dbt)
 * @param cidutDoc документ
 * @param cidutLink ссылка
 * @param cidutSheet лист (dbt)
 * @param cidutSheetNum номер строки/листа
 * @param cidutUnloadKey upl/pm
 * @param source {@code dbt} или {@code pmt}
 * @param pmtCdtBlns кредит (pmt)
 * @param pmtCdtBlnsOverd просрочка кредита (pmt)
 * @param pmtDocSum сумма документа СФ (pmt)
 * @param pmtBlns баланс (pmt)
 * @param pmtBe БЕ (pmt)
 * @param pmtCac код стройки (pmt)
 * @param pmtAgentNum номер агента (pmt)
 * @param pmtAgentName имя агента (pmt)
 * @param pmtSfBlnsSum итог сальдо по присвоению СФ (pmt)
 * @param pmtSfBlnsRows число строк Tbl в группе сальдо (pmt)
 */
public record SudzSfDoubleExcelCandidate(
        int cidutKey,
        Integer findDbtNum,
        Integer cidutAccount,
        Integer cidutAccntNum,
        Integer cidutCntrPrtNum,
        String cidutCntrPrtName,
        String cidutCntrPrtITN,
        String cidutCnName,
        LocalDate cidutCnDate,
        String cidutCnInv,
        String cidutCnInvName,
        LocalDate cidutFormtnDate,
        LocalDate cidutMatrtyDate,
        BigDecimal cidutDebt,
        BigDecimal cidutDebtOverdue,
        String cidutDoc,
        String cidutLink,
        Integer cidutSheet,
        Integer cidutSheetNum,
        Integer cidutUnloadKey,
        String source,
        BigDecimal pmtCdtBlns,
        BigDecimal pmtCdtBlnsOverd,
        BigDecimal pmtDocSum,
        BigDecimal pmtBlns,
        String pmtBe,
        String pmtCac,
        Integer pmtAgentNum,
        String pmtAgentName,
        BigDecimal pmtSfBlnsSum,
        Integer pmtSfBlnsRows
) {
    /**
     * Кандидат свода (dbt) без pmt-сумм.
     */
    public static SudzSfDoubleExcelCandidate dbt(
            int cidutKey,
            Integer findDbtNum,
            Integer cidutAccount,
            Integer cidutAccntNum,
            Integer cidutCntrPrtNum,
            String cidutCntrPrtName,
            String cidutCntrPrtITN,
            String cidutCnName,
            LocalDate cidutCnDate,
            String cidutCnInv,
            String cidutCnInvName,
            LocalDate cidutFormtnDate,
            LocalDate cidutMatrtyDate,
            BigDecimal cidutDebt,
            BigDecimal cidutDebtOverdue,
            String cidutDoc,
            String cidutLink,
            Integer cidutSheet,
            Integer cidutSheetNum,
            Integer cidutUnloadKey
    ) {
        return new SudzSfDoubleExcelCandidate(
                cidutKey, findDbtNum, cidutAccount, cidutAccntNum, cidutCntrPrtNum, cidutCntrPrtName,
                cidutCntrPrtITN, cidutCnName, cidutCnDate, cidutCnInv, cidutCnInvName, cidutFormtnDate,
                cidutMatrtyDate, cidutDebt, cidutDebtOverdue, cidutDoc, cidutLink, cidutSheet,
                cidutSheetNum, cidutUnloadKey, "dbt", null, null, null, null, null, null, null, null,
                null, null);
    }
}
