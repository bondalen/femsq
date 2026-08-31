package com.femsq.database.model.sudz;

/**
 * Лист файла загрузки свода ({@code CnInvDbtUplFileSh}).
 *
 * @param cidufsKey ключ листа
 * @param cidufsFile ключ {@code CnInvDbtUplFile}
 * @param cidufsSheet имя листа
 * @param cidufsAccount ключ счёта ({@code ags.accnt.account_key})
 * @param cidufsTest флаг «проверять?»
 * @param accountNum номер счёта ГК ({@code ags.accnt.account_num}), для UI
 */
public record SudzDbtUplFileSh(
        int cidufsKey,
        int cidufsFile,
        String cidufsSheet,
        int cidufsAccount,
        boolean cidufsTest,
        Integer accountNum
) {
}
