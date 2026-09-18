package com.femsq.database.model.sudz;

/**
 * Итог find шага {@code cipuInsPmNotLoad}: число готовых платежей без {@code cn_inv_pm}.
 *
 * @param readyCount число строк к INSERT (Access: RecordCount {@code cipuInsPmNot})
 */
public record SudzPmtUplInsPmNotResult(int readyCount) {
}
