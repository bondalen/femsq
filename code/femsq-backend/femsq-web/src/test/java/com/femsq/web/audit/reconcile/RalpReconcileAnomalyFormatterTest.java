package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты текстов аномалий сверки RALP (0051 / §9.3.6.4).
 */
class RalpReconcileAnomalyFormatterTest {

    @Test
    void formatEmptyArrivedHtml_includesExcelRow() {
        String html = RalpReconcileAnomalyFormatter.formatEmptyArrivedHtml(
                55, "0126/310126", LocalDate.of(2026, 1, 31));
        assertTrue(html.contains("Excel-строка"));
        assertTrue(html.contains("femsq-anomaly-ref"));
        assertTrue(html.contains("0126/310126"));
        assertTrue(html.contains("31.01.2026"));
        assertTrue(!html.contains("рассмотрение не обрабатывается"), html);
    }

    @Test
    void formatInvalidReferToStage2Html() {
        assertEquals(
                "<P>Сверка: некорректных строк = 4 (причины и Excel-строки — в предупреждениях Этапа 2 выше).</P>",
                RalpReconcileAnomalyFormatter.formatInvalidReferToStage2Html(4)
        );
    }

    @Test
    void formatOrphanReportsHtml_accessStyle() {
        String html = RalpReconcileAnomalyFormatter.formatOrphanReportsHtml(
                List.of("A-1", "B-2"), true);
        assertTrue(html.contains("Лишние отчёты в БД"));
        assertTrue(html.contains("1. "));
        assertTrue(html.contains("A-1"));
        assertTrue(html.contains("B-2"));
    }

    @Test
    void formatDemoteHtml_sentAndInProcess() {
        String sent = RalpReconcileAnomalyFormatter.formatDemoteHtml(
                10, "137/310126", "п. 1 от 01.01.2026", true, true);
        assertTrue(sent.contains("sent→returned"));
        String closed = RalpReconcileAnomalyFormatter.formatDemoteHtml(
                null, "396/280226", "п. 2", false, false);
        assertTrue(closed.contains("(dry-run)"));
        assertTrue(closed.contains("in-process→returned"));
    }
}
