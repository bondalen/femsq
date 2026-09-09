package com.femsq.web.api.dto.sudz;

/**
 * Вход upsert {@code DbtValue} на слоте канона (S78.4D).
 *
 * @param slotKey слот invDbt
 * @param uplKey выгрузка
 * @param ttl сумма
 * @param overd просрочка
 * @param valueKey ключ для UPDATE; null — INSERT
 */
public record UpsertSudzDbtCanonValueInput(
        int slotKey,
        int uplKey,
        double ttl,
        Double overd,
        Integer valueKey
) {
}
