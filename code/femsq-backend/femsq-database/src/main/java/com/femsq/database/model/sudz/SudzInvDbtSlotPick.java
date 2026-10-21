package com.femsq.database.model.sudz;

/**
 * Слот {@code invDbt} в поиске для привязки к канону.
 *
 * @param slotKey ключ слота ({@code idKey})
 * @param iKey счёт-фактура ({@code idInv})
 * @param idNum номер слота на СФ
 * @param invNum номер СФ
 * @param cnNum номер договора
 * @param dbtKey канон, к которому слот уже привязан; {@code null}, если моста нет
 */
public record SudzInvDbtSlotPick(
        int slotKey,
        int iKey,
        int idNum,
        String invNum,
        String cnNum,
        Integer dbtKey
) {
}
