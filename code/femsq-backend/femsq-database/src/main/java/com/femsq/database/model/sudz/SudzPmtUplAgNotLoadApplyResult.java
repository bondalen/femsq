package com.femsq.database.model.sudz;

import java.util.Map;
import java.util.Objects;

/**
 * Итог apply шага 5 {@code cipuCn_AgNotLoad}.
 *
 * @param note заметка вставки
 * @param insertedByRowIndex ключи по индексу строки find (1-based)
 * @param insertedCount число успешных INSERT
 */
public record SudzPmtUplAgNotLoadApplyResult(
        String note,
        Map<Integer, SudzPmtUplAgNotLoadInserted> insertedByRowIndex,
        int insertedCount
) {
    /**
     * @param note заметка
     * @param insertedByRowIndex карта
     * @param insertedCount счётчик
     */
    public SudzPmtUplAgNotLoadApplyResult {
        Objects.requireNonNull(note, "note");
        insertedByRowIndex = insertedByRowIndex == null ? Map.of() : Map.copyOf(insertedByRowIndex);
    }

    /**
     * Пустой итог.
     *
     * @param note заметка
     * @return пустой результат
     */
    public static SudzPmtUplAgNotLoadApplyResult empty(String note) {
        return new SudzPmtUplAgNotLoadApplyResult(note, Map.of(), 0);
    }
}
