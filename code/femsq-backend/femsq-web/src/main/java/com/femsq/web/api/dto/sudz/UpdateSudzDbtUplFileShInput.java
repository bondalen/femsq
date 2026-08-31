package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input обновления листа {@code CnInvDbtUplFileSh}.
 *
 * @param cidufsKey ключ листа
 * @param sheet имя; null — не менять
 * @param accountNum номер счёта; null — не менять
 * @param test флаг; null — не менять
 */
public record UpdateSudzDbtUplFileShInput(
        int cidufsKey,
        String sheet,
        Integer accountNum,
        Boolean test
) {
}
