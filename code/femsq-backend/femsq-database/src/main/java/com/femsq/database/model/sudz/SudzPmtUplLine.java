package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Одна строка сверки книги и {@code cn_inv_pm}: документ, лист, срок,
 * дата выравнивания и семь сумм. Стройка в набор не входит.
 *
 * @param docCode «№ докум.»
 * @param sheet номер листа
 * @param due срок оплаты
 * @param alignment дата выравнивания
 * @param dbtBlns дебет
 * @param dbtBlnsOverd дебет просроченный
 * @param dbtBlnsNotOverd дебет не просроченный
 * @param cdtBlns кредит
 * @param cdtBlnsOverd кредит просроченный
 * @param cdtBlnsNotOverd кредит не просроченный
 * @param blns сальдо
 */
public record SudzPmtUplLine(
        String docCode,
        Integer sheet,
        LocalDateTime due,
        LocalDateTime alignment,
        BigDecimal dbtBlns,
        BigDecimal dbtBlnsOverd,
        BigDecimal dbtBlnsNotOverd,
        BigDecimal cdtBlns,
        BigDecimal cdtBlnsOverd,
        BigDecimal cdtBlnsNotOverd,
        BigDecimal blns
) {
}
