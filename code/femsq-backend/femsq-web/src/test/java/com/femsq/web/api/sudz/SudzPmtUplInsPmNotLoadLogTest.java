package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplInsPmNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplInsPmNotResult;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 12 платежей.
 */
class SudzPmtUplInsPmNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplInsPmNotLoadLog.append(log, new SudzPmtUplInsPmNotResult(0), null);
        assertTrue(log.toHtml().contains("отсутствуют платежи"));
    }

    @Test
    void appendWithReadyAndApply() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplInsPmNotLoadLog.append(
                log,
                new SudzPmtUplInsPmNotResult(303),
                new SudzPmtUplInsPmNotApplyResult(303));
        String html = log.toHtml();
        assertTrue(html.contains("количестве 303"));
        assertTrue(html.contains("Внесено платежи"));
    }
}
