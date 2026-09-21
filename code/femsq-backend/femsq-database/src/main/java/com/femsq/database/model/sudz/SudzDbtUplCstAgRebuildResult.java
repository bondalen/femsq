package com.femsq.database.model.sudz;

/**
 * Итог пересчёта {@code sudz.DbtUplCstAg} по политике P1 (H6 / usp).
 *
 * @param dbtUplKey выгрузка ДЗ ({@code ducaUpl})
 * @param deletedCount сколько строк снято перед пересчётом
 * @param insertedCount сколько строк A+B+C вставлено (все Value@upl)
 * @param multiCount корзина B ({@code кодов - N})
 * @param emptyCount корзина C («не обнаружена в платежах»)
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
