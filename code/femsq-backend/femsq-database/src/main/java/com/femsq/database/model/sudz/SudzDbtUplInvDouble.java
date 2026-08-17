package com.femsq.database.model.sudz;

/**
 * Строка очереди неоднозначных СФ ({@code CnInvDbtUplFileInvDouble}).
 *
 * @param cidufiKey ключ
 * @param cidufiCiduf ключ файла
 * @param cidufiCnNnn номер договора (служебный)
 * @param cidufiCnNum номер договора
 * @param cidufiCnKey ключ договора
 * @param cidufiInvNnn номер СФ (служебный)
 * @param cidufiInvNum номер СФ
 * @param cidufiInvNumCount число совпадений (как текст в Access)
 */
public record SudzDbtUplInvDouble(
        int cidufiKey,
        Integer cidufiCiduf,
        Integer cidufiCnNnn,
        String cidufiCnNum,
        Integer cidufiCnKey,
        Integer cidufiInvNnn,
        String cidufiInvNum,
        String cidufiInvNumCount
) {
}
