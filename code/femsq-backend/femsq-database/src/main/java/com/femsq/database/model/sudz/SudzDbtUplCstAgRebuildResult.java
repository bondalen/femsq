package com.femsq.database.model.sudz;

/**
 * Итог пересчёта {@code sudz.DbtUplCstAg} по канону fn+g_p (H6).
 *
 * @param dbtUplKey выгрузка ДЗ ({@code ducaUpl})
 * @param deletedCount сколько строк бэкфилла/старых снято
 * @param insertedCount сколько однозначных (dbt,upl)→cstAgPn вставлено
 * @param multiCount сколько dbt с &gt;1 кодом стройки (пропущены)
 * @param emptyCount сколько dbt@upl без однозначного cst из pm+g_p
 * @param opsProgress актуальный {@code cidufOpsProgress} после append
 */
public record SudzDbtUplCstAgRebuildResult(
        int dbtUplKey,
        int deletedCount,
        int insertedCount,
        int multiCount,
        int emptyCount,
        String opsProgress
) {
}
