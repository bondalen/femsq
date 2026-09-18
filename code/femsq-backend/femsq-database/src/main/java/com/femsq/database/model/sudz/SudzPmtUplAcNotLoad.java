package com.femsq.database.model.sudz;

/**
 * Строка diff шага {@code cipuCn_CtptCnOneInvOneAcNotLoad}:
 * есть ровно одна СФ на договоре, нет {@code cnInvAccntSmpl} на (ci, csos, accnt).
 *
 * @param ciKey ключ {@code cnInv}
 * @param csosKey smpl исполнителя
 * @param accountNum номер счёта ГК из Excel
 * @param accountKey ключ {@code accnt}
 * @param buirg БУиРГ
 * @param name наименование
 * @param cnName номер договора
 * @param cnKey договор
 * @param cnInv номер СФ
 */
public record SudzPmtUplAcNotLoad(
        int ciKey,
        int csosKey,
        int accountNum,
        int accountKey,
        Integer buirg,
        String name,
        String cnName,
        int cnKey,
        String cnInv
) {
}
