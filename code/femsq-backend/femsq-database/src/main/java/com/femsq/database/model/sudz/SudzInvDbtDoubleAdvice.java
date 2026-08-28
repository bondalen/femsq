package com.femsq.database.model.sudz;

/**
 * Советник оператора КСДД (сегм. 22c): текст для панели «Сообщения».
 *
 * @param messageText блок {@code [advisor]} (plain text)
 * @param confidence {@code high}, {@code medium}, {@code low}, {@code none}
 * @param action {@code link}, {@code create_var}, {@code create_slot}, {@code manual}
 * @param recommendIdKey рекомендуемый слот invDbt
 * @param recommendVarKey var очереди / слота
 */
public record SudzInvDbtDoubleAdvice(
        String messageText,
        String confidence,
        String action,
        Integer recommendIdKey,
        Integer recommendVarKey
) {
}
