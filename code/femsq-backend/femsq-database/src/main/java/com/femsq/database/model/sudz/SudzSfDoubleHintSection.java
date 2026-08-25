package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Секция подсказок КСДСФ (СФ по номеру / суммы old / суммы new).
 *
 * @param status {@code yes} | {@code no} | {@code unknown} | {@code na}
 * @param message текст для оператора
 * @param totalCount полное число совпадений (может быть &gt; items.size)
 * @param items первые совпадения (для клика по ключу)
 */
public record SudzSfDoubleHintSection(
        String status,
        String message,
        int totalCount,
        List<SudzSfDoubleHintItem> items
) {
}
