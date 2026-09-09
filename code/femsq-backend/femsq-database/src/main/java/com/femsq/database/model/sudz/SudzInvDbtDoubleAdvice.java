package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Советник оператора КСДД (сегм. 22c): текст для панели «Сообщения».
 *
 * @param messageText блок {@code [advisor]} (plain text)
 * @param confidence {@code high}, {@code medium}, {@code low}, {@code none}
 * @param action {@code split}, {@code link}, {@code create_var}, {@code create_slot}, {@code manual}
 * @param recommendIdKey рекомендуемый слот invDbt
 * @param recommendVarKey var очереди / слота
 * @param recommendDbtKey канон при {@code split}
 * @param recommendUplKey срез при {@code split}
 * @param splitParts доли для {@code splitSudzDbt}; иначе пусто
 */
public record SudzInvDbtDoubleAdvice(
        String messageText,
        String confidence,
        String action,
        Integer recommendIdKey,
        Integer recommendVarKey,
        Integer recommendDbtKey,
        Integer recommendUplKey,
        List<SudzDbtSplitPart> splitParts
) {
    /**
     * Совет без Split-пейлоада.
     *
     * @param messageText текст
     * @param confidence уверенность
     * @param action действие
     * @param recommendIdKey слот
     * @param recommendVarKey var
     */
    public SudzInvDbtDoubleAdvice(
            String messageText,
            String confidence,
            String action,
            Integer recommendIdKey,
            Integer recommendVarKey
    ) {
        this(messageText, confidence, action, recommendIdKey, recommendVarKey, null, null, List.of());
    }

    /**
     * Пустой {@code splitParts} → пустой список.
     */
    public SudzInvDbtDoubleAdvice {
        if (splitParts == null) {
            splitParts = List.of();
        }
    }
}
