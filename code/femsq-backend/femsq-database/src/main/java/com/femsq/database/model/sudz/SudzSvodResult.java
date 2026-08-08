package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Результат {@code sudz.Yr_DbtChangesD644Svod}.
 */
public record SudzSvodResult(
        List<SudzSvodAccount> accounts,
        SudzSvodTotal total
) {
}
