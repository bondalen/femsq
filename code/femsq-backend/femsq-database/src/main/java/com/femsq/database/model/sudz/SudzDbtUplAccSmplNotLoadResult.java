package com.femsq.database.model.sudz;

import java.util.List;
import java.util.Objects;

/**
 * Diff + apply шага {@code CnCtptInvExistAccSmplNotLoad} за один проход
 * (один {@code fillSudzEiaTemp}).
 *
 * @param rows строки diff для HTML-лога
 * @param apply итог INSERT (не null при вызове findAndApply)
 */
public record SudzDbtUplAccSmplNotLoadResult(
        List<SudzDbtUplAccSmplNotRow> rows,
        SudzDbtUplAccSmplNotApplyResult apply
) {

    public SudzDbtUplAccSmplNotLoadResult {
        Objects.requireNonNull(rows, "rows");
        Objects.requireNonNull(apply, "apply");
        rows = List.copyOf(rows);
    }
}
