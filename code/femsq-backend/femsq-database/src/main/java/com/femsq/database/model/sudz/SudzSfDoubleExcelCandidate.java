package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Карточка Excel-кандидата из {@code CnInvDbtUplTbl} для КСДСФ.
 */
public record SudzSfDoubleExcelCandidate(
        int cidutKey,
        Integer findDbtNum,
        Integer cidutAccount,
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
}
