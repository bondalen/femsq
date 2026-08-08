package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Долг в витрине Rslt (зерно {@code dbtKey}).
 */
public record SudzRsltDebt(
        int dbtKey,
        String accountNum,
        String curator,
        String mery,
        String cstCode,
        String cstName,
        List<SudzRsltPeriod> periods
) {
}
