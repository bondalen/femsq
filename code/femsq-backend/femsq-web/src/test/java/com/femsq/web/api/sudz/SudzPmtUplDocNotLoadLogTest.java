package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 10 платежей.
 */
class SudzPmtUplDocNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplDocNotLoadLog.append(log, List.of(), null);
        assertTrue(log.toHtml().contains("отсутствуют документы"));
    }

    @Test
    void appendWithCodes() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplDocNotLoadLog.append(log, List.of("5500006768", "5500006769"), null);
        String html = log.toHtml();
        assertTrue(html.contains("количестве"));
        assertTrue(html.contains("5500006768"));
    }
}
