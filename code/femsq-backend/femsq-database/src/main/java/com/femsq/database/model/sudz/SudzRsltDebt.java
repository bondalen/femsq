package com.femsq.database.model.sudz;

import java.util.List;

/**
 * Долг в витрине Rslt (зерно {@code dbtKey}).
 *
 * @param curatorNew куратор из {@code yr_CmmGr_New} (колонка {@code cur_new}; только Rslt повтор)
 * @param meryNew мероприятия из {@code yr_CmmGr_New} ({@code mery_new})
 * @param cstCodeNew код стройки из {@code yr_CmmGr_New} ({@code cstAgPn_new})
 */
public record SudzRsltDebt(
        int dbtKey,
        String accountNum,
        String curator,
        String mery,
        String cstCode,
        String cstName,
        String curatorNew,
        String meryNew,
        String cstCodeNew,
        List<SudzRsltPeriod> periods
) {
}
