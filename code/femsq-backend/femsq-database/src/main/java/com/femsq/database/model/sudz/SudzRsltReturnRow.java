package com.femsq.database.model.sudz;

/**
 * Строка импорта возврата Rslt (колонки {@code *_new}).
 *
 * @param dbtKey       ключ долга
 * @param curatorNew   куратор ({@code cur_new})
 * @param meryNew      мероприятия ({@code mery_new})
 * @param cstCodeNew   код стройки ({@code cstAgPn_new})
 * @param bandOrdinal  0-based номер строки полосы этого {@code dbtKey} (стыковка с Value крайней upl)
 */
public record SudzRsltReturnRow(
        int dbtKey,
        String curatorNew,
        String meryNew,
        String cstCodeNew,
        int bandOrdinal
) {
    /**
     * Строка без ординала полосы (одна доля / тесты).
     */
    public SudzRsltReturnRow(int dbtKey, String curatorNew, String meryNew, String cstCodeNew) {
        this(dbtKey, curatorNew, meryNew, cstCodeNew, 0);
    }
}
