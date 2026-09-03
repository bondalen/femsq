package com.femsq.database.model.sudz;

/**
 * Советник оператора КСДСФ: текст для панели «Сообщения».
 *
 * @param messageText блок {@code [советник]} (plain text)
 * @param confidence {@code high}, {@code medium}, {@code low}, {@code none}
 * @param action {@code link}, {@code create}, {@code manual}
 * @param recommendInvKey рекомендуемый {@code ags.inv.iKey} для связи
 * @param recommendCnKey договор Excel / целевой cn
 */
public record SudzSfDoubleAdvice(
        String messageText,
        String confidence,
        String action,
        Integer recommendInvKey,
        Integer recommendCnKey
) {
}
