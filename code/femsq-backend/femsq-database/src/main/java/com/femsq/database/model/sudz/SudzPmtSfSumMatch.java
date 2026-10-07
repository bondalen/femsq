package com.femsq.database.model.sudz;

import java.math.BigDecimal;

/**
 * Строка свода, с которой сверяется итог сальдо платежей по СФ.
 *
 * @param dbtUplKey выгрузка свода ({@code cn_inv_dbt_upl})
 * @param cidutKey строка {@code CnInvDbtUplTbl}
 * @param invNum номер СФ в своде
 * @param accountNum номер счёта ГК
 * @param debt долг свода
 * @param debtOverdue просрочка свода
 * @param cnName договор (текст Excel свода)
 */
public record SudzPmtSfSumMatch(
        int dbtUplKey,
        int cidutKey,
        String invNum,
        Integer accountNum,
        BigDecimal debt,
        BigDecimal debtOverdue,
        String cnName
) {
}
