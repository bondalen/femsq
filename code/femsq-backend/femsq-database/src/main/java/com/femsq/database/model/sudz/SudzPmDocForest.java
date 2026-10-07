package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Лес платёжных документов: коды строки и уже записанные в базу привязки.
 *
 * @param fileCodes сколько кодов «№ докум.» у строки очереди; для входа по inv — 0
 * @param matchedDocs сколько из них нашлось в {@code cn_inv_doc} с платежами
 * @param currentUplKey пакет строки очереди, чтобы отметить его в лесу; для входа по inv — null
 * @param links платежи этих документов
 */
public record SudzPmDocForest(
        int fileCodes,
        int matchedDocs,
        Integer currentUplKey,
        List<SudzPmDocLink> links
) {
    /**
     * Пустой лес.
     */
    public static SudzPmDocForest empty() {
        return new SudzPmDocForest(0, 0, null, List.of());
    }
}
