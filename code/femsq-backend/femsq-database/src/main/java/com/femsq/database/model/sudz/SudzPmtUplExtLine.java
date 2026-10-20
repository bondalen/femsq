package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Строка сверки InsPmExt: документ, лист, срок, выравнивание, семь сумм и код стройки.
 * Книга берёт код из {@code ciputCAC}/{@code ciputLink}, платёж — из {@code cstAgPn}.
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
 * @param cac код стройки; пусто, если связи нет
 */
public record SudzPmtUplExtLine(
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
        BigDecimal blns,
        String cac
) {
}
