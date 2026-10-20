package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Строка вкладки «счета, сумма» (Access {@code CnInvPmtUpl>Sum_t}).
 * Источник — {@code ags.q_cn_inv_pm_upl_sum}: суммы {@code cn_inv_pm}
 * по счёту ГК. Строка с {@code accountNum == null} — итог пакета из {@code ROLLUP}.
 *
 * @param pmKey пакет {@code cn_inv_pm_upl}
 * @param accountNum счёт ГК или null для итога пакета
 * @param dbtBlns сумма дебетового сальдо
 * @param dbtBlnsOverd сумма просроченного дебета
 * @param dbtBlnsNotOverd сумма непросроченного дебета
 * @param cdtBlns сумма кредитового сальдо
 * @param cdtBlnsOverd сумма просроченного кредита
 * @param cdtBlnsNotOverd сумма непросроченного кредита
 * @param blns сумма сальдо
 */
public record SudzPmtUplSum(
        int pmKey,
        Integer accountNum,
        BigDecimal dbtBlns,
        BigDecimal dbtBlnsOverd,
        BigDecimal dbtBlnsNotOverd,
        BigDecimal cdtBlns,
        BigDecimal cdtBlnsOverd,
        BigDecimal cdtBlnsNotOverd,
        BigDecimal blns
) {

    /**
     * @param pmKey пакет
     * @param accountNum счёт ГК или null
     * @param dbtBlns дебет
     * @param dbtBlnsOverd дебет просроченный
     * @param dbtBlnsNotOverd дебет непросроченный
     * @param cdtBlns кредит
     * @param cdtBlnsOverd кредит просроченный
     * @param cdtBlnsNotOverd кредит непросроченный
     * @param blns сальдо
     */
    public SudzPmtUplSum {
        if (pmKey <= 0) {
            throw new IllegalArgumentException("pmKey должен быть положительным: " + pmKey);
        }
    }
}
