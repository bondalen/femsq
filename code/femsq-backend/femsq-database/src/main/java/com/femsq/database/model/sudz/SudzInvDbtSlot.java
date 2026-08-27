package com.femsq.database.model.sudz;

/**
 * Слот {@code sudz.invDbt} для экрана двоящих долгов.
 *
 * @param idKey ключ слота
 * @param idInv {@code ags.inv.iKey}
 * @param idNum порядковый номер на СФ
 * @param idNote заметка
 */
public record SudzInvDbtSlot(
        int idKey,
        int idInv,
        int idNum,
        String idNote
) {
}
