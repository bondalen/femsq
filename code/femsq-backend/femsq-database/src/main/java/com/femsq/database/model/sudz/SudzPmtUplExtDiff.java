package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Итог построчной сверки книги и платежей пакета. {@code gaps} обрезан для экрана,
 * {@code gapCount} — полное число отличий.
 *
 * @param bookRows строк книги с «№ докум.»
 * @param dbRows платежей пакета
 * @param gapCount полное число отличий
 * @param gaps первые отличия для грида
 */
public record SudzPmtUplExtDiff(
        int bookRows,
        int dbRows,
        int gapCount,
        List<SudzPmtUplExtGap> gaps
) {
}
