package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Строка очереди разбора двоящих задолженностей СФ
 * ({@code sudz.CnInvUplInvDbtDouble}).
 *
 * @param ciudKey ключ
 * @param ciudCidut FK строка Excel ({@code CnInvDbtUplTbl})
 * @param ciudDbtFile ключ File долгов
 * @param ciudUnloadKey upl_key
 * @param ciudIKey {@code ags.inv.iKey}
 * @param ciudCnNum номер договора
 * @param ciudInvNum номер СФ
 * @param ciudDebt сумма долга из Excel
 * @param ciudIdvvKey {@code invDbtVar} если известен
 * @param ciudReason multi|ambiguous|sum
 * @param ciudStatus open|created|deferred
 * @param ciudStatusAt время смены статуса
 * @param ciudCreatedIdKey {@code invDbt.idKey} после create
 */
public record SudzCnInvUplInvDbtDouble(
        int ciudKey,
        int ciudCidut,
        Integer ciudDbtFile,
        int ciudUnloadKey,
        Integer ciudIKey,
        String ciudCnNum,
        String ciudInvNum,
        BigDecimal ciudDebt,
        Integer ciudIdvvKey,
        String ciudReason,
        String ciudStatus,
        OffsetDateTime ciudStatusAt,
        Integer ciudCreatedIdKey
) {
}
