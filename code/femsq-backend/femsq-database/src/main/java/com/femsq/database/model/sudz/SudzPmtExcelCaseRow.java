package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Белая строка Excel кейса КСДСФ pmt (кредитор + договор + номер).
 * Колонки как в файле: «№ докум.» / «Ссылка», без сдвоенных doc/link-подписей DTO долга.
 *
 * @param ciputKey ключ строки Tbl
 * @param sheetNum индекс листа книги (1-based)
 * @param docCode «№ докум.» ({@code ciputCnInvDocCode})
 * @param link «Ссылка» ({@code ciputLink})
 * @param entryDate дата проводки
 * @param dueDate срок
 * @param cac стройка
 * @param be БЕ
 * @param blns сальдо строки
 * @param cdtBlns кредит
 * @param docSum сумма документа
 * @param dueGrp номер жёлтой группы срока (staging)
 */
public record SudzPmtExcelCaseRow(
        int ciputKey,
        Integer sheetNum,
        String docCode,
        String link,
        LocalDate entryDate,
        LocalDate dueDate,
        String cac,
        String be,
        BigDecimal blns,
        BigDecimal cdtBlns,
        BigDecimal docSum,
        Integer dueGrp
) {
}
