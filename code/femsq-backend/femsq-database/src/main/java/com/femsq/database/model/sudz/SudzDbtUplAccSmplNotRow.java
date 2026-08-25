package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Строка diff шага {@code CnCtptInvExistAccSmplNotLoad}
 * (Access {@code ciduCnCtptInvAccSmplNot}): СФ есть, нет {@code cnInvAccntSmpl}
 * по тройке ({@code ciKey}, {@code account_key}, БУиРГ).
 *
 * {@code csosKey} в лог Access не входит — INSERT берёт его отдельно
 * ({@code ciduCnCtptInvAccSmplNotIns}, без даты договора).
 *
 * @param cntrPrtNum БУиРГ Excel
 * @param cntrPrtName имя контрагента
 * @param cnName номер договора
 * @param cnDate дата договора (null = отсутствует)
 * @param cnKey договор
 * @param cnInv номер СФ
 * @param iKey ключ {@code inv}
 * @param ciKey ключ {@code cnInv}
 * @param accountNum номер счёта ГК
 * @param accountKey ключ {@code accnt}
 */
public record SudzDbtUplAccSmplNotRow(
        Integer cntrPrtNum,
        String cntrPrtName,
        String cnName,
        LocalDate cnDate,
        int cnKey,
        String cnInv,
        int iKey,
        int ciKey,
        int accountNum,
        int accountKey
) {
}
