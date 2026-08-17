package com.femsq.database.model.sudz;

import java.util.Map;

/**
 * Итог apply шага {@code CnNotLoad}.
 *
 * @param cnMark метка {@code ags.cn.cnMark} для отката
 * @param note текст {@code cn_note} / {@code cnnNote}
 * @param insertedByRowIndex вставки по индексу строки в списке лога (1-based); нет ключа — не вставляли
 * @param insertedCount число успешно вставленных договоров
 */
public record SudzDbtUplCnNotLoadApplyResult(
        int cnMark,
        String note,
        Map<Integer, SudzDbtUplCnNotLoadInserted> insertedByRowIndex,
        int insertedCount
) {
    /**
     * Компактный конструктор: неизменяемая карта.
     */
    public SudzDbtUplCnNotLoadApplyResult {
        insertedByRowIndex = Map.copyOf(insertedByRowIndex);
    }

    /**
     * Пустой apply (нечего вставлять).
     *
     * @param cnMark метка (всё равно фиксируем для лога)
     * @param note примечание
     * @return результат
     */
    public static SudzDbtUplCnNotLoadApplyResult empty(int cnMark, String note) {
        return new SudzDbtUplCnNotLoadApplyResult(cnMark, note, Map.of(), 0);
    }
}
