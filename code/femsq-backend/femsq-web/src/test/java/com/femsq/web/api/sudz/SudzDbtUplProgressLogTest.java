package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Свёртка и хронология лога воронки.
 */
class SudzDbtUplProgressLogTest {

    @Test
    void chronologicalNestedDetails() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        log.line("start");
        log.open("excelToTbl", true);
        log.line("file");
        log.open("Лист 606012 — 2", false);
        log.line("inv-1");
        log.line("inv-2");
        log.close();
        log.close();
        log.line("end");
        String html = log.toHtml();
        assertTrue(html.indexOf("start") < html.indexOf("excelToTbl"));
        assertTrue(html.indexOf("excelToTbl") < html.indexOf("Лист 606012"));
        assertTrue(html.indexOf("inv-1") < html.indexOf("inv-2"));
        assertTrue(html.indexOf("inv-2") < html.indexOf("end"));
        assertTrue(html.contains("<details"));
        assertTrue(html.contains("sudz-funnel-log-pm"));
        assertTrue(html.contains("open"));
    }
}
