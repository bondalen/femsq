package com.femsq.web.api.sudz.repay;

import java.math.BigDecimal;

/**
 * Строка разбора погашения (карточка S79.6): только классы, которые смотрит оператор.
 *
 * @param dbtKey канон долга
 * @param accountNum счёт
 * @param invNum последний номер СФ
 * @param cnNum последний номер договора
 * @param kind partial_reduce или full_disappear
 * @param clazz suspect или ambiguous
 * @param reason код правила
 * @param pogasheno сумма «погашено» на крайнем срезе
 */
public record SudzRsltRepaymentCase(
        int dbtKey,
        String accountNum,
        String invNum,
        String cnNum,
        String kind,
        String clazz,
        String reason,
        BigDecimal pogasheno
) {
}
