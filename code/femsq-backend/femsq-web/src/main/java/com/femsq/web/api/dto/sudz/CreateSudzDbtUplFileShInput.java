package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input создания листа {@code CnInvDbtUplFileSh}.
 *
 * @param uplKey ключ выгрузки
 * @param sheet имя листа Excel
 * @param accountNum номер счёта ГК ({@code ags.accnt.account_num})
 * @param test флаг «проверять?»
 */
public record CreateSudzDbtUplFileShInput(
        int uplKey,
        String sheet,
        int accountNum,
        boolean test
) {
}
