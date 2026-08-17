package com.femsq.database.model.sudz;

/**
 * Лист файла загрузки свода ({@code CnInvDbtUplFileSh}).
 *
 * @param cidufsKey ключ листа
 * @param cidufsFile ключ {@code CnInvDbtUplFile}
 * @param cidufsSheet имя листа
 * @param cidufsAccount ключ счёта ({@code ags.accnt})
 * @param cidufsTest флаг «проверять?»
 */
public record SudzDbtUplFileSh(
        int cidufsKey,
        int cidufsFile,
        String cidufsSheet,
        int cidufsAccount,
        boolean cidufsTest
) {
}
