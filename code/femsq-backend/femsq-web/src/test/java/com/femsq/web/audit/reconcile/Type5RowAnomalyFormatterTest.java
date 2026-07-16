package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты построчных WARN type=5 (0051 / §9.3.6.5).
 */
class Type5RowAnomalyFormatterTest {

    @Test
    void formatRaFailHtml_invalidWithExcelRow() {
        String html = Type5RowAnomalyFormatter.formatRaFailHtml(
                4601,
                "ГП26-2001234-1",
                LocalDate.of(2026, 3, 31),
                "INVALID_CANONICAL_KEY",
                "стройка «002-2001234» не найдена"
        );
        assertTrue(html.contains("Excel-строка"));
        assertTrue(html.contains("femsq-anomaly-ref"));
        assertTrue(html.contains(">4601</span>"));
        assertTrue(html.contains("лист «Отчеты»"));
        assertTrue(html.contains("ГП26-2001234-1"));
        assertTrue(html.contains("femsq-anomaly-val"));
        assertTrue(html.contains("002-2001234"));
        assertTrue(html.contains("некорректная"));
        assertTrue(html.contains("INVALID_CANONICAL_KEY"));
    }

    @Test
    void formatRaFailHtml_ambiguous() {
        String html = Type5RowAnomalyFormatter.formatRaFailHtml(
                10, "X", null, "AMBIGUOUS_MATCH", "Найдено 2 записи");
        assertTrue(html.contains("неоднозначная"));
    }

    @Test
    void formatRcFailHtml_missingExcelRowFallback() {
        String html = Type5RowAnomalyFormatter.formatRcFailHtml(
                null, "Изм 1 …", LocalDate.of(2026, 1, 1), "RC_MISSING_BASE_RA", "нет RA");
        assertTrue(html.contains("номер Excel неизвестен"));
        assertTrue(html.contains("ОА изм"));
        assertTrue(html.contains("некорректная"));
    }

    @Test
    void humanOutcomes() {
        assertEquals("неоднозначная", Type5RowAnomalyFormatter.humanRaOutcome("AMBIGUOUS_MATCH"));
        assertEquals("некорректная", Type5RowAnomalyFormatter.humanRaOutcome("DISALLOWED_SIGN"));
        assertEquals("неоднозначная", Type5RowAnomalyFormatter.humanRcOutcome("RC_AMBIGUOUS_BASE_RA"));
    }
}
