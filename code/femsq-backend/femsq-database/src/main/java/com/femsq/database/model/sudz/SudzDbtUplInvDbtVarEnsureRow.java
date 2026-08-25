package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Строка шага {@code invDbtVarEnsure}: контекст задолженности и наличие
 * {@code sudz.invDbtVar} по UNIQUE-четвёрке FK.
 *
 * @param cntrPrtNum БУиРГ
 * @param cntrPrtName наименование контрагента
 * @param cnName номер договора
 * @param cnDate дата договора
 * @param cnInv номер СФ из Excel
 * @param iKey ключ {@code ags.inv}
 * @param accountKey {@code ags.accnt.account_key} (= {@code cidutAccount})
 * @param accountNum номер СГК
 * @param cnnKey уникальный {@code cnNum.cnnKey} (cnnType=1) или null
 * @param inKey уникальный {@code invNum.inKey} или null
 * @param cnSOrgKey {@code cn_s_org_key}
 * @param idvvKeyNullable ключ {@code invDbtVar} или null, если строки ещё нет
 */
public record SudzDbtUplInvDbtVarEnsureRow(
        Integer cntrPrtNum,
        String cntrPrtName,
        String cnName,
        LocalDate cnDate,
        String cnInv,
        int iKey,
        int accountKey,
        int accountNum,
        Integer cnnKey,
        Integer inKey,
        int cnSOrgKey,
        Integer idvvKeyNullable
) {
}
