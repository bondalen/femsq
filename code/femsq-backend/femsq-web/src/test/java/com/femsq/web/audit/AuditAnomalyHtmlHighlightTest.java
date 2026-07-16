package com.femsq.web.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Unit-тесты HTML-подсветки аномальных значений.
 */
class AuditAnomalyHtmlHighlightTest {

    @Test
    void guillemet_wrapsEscapedValue() {
        String html = AuditAnomalyHtmlHighlight.guillemet("026-3005711");
        assertEquals(
                "«<span class=\"femsq-anomaly-val\">026-3005711</span>»",
                html
        );
    }

    @Test
    void ref_andExcelRowPrefix() {
        assertEquals(
                "<span class=\"femsq-anomaly-ref\">91</span>",
                AuditAnomalyHtmlHighlight.ref(91)
        );
        assertEquals(
                "«<span class=\"femsq-anomaly-ref\">0126/310126</span>»",
                AuditAnomalyHtmlHighlight.guillemetRef("0126/310126")
        );
        String prefix = AuditAnomalyHtmlHighlight.excelRowPrefixHtml(91, "Аренда_Земли");
        assertTrue(prefix.contains("femsq-anomaly-ref"));
        assertTrue(prefix.contains(">91</span>"));
        assertTrue(prefix.contains("лист «Аренда_Земли»"));
    }

    @Test
    void highlightGuillemetValues_multipleAndEscapes() {
        String html = AuditAnomalyHtmlHighlight.highlightGuillemetValues(
                "отправитель «Газпром <инвест>» / «Газпром Ремонт»");
        assertTrue(html.contains("femsq-anomaly-val"));
        assertTrue(html.contains("Газпром &lt;инвест&gt;"));
        assertTrue(html.contains("Газпром Ремонт"));
        assertTrue(html.startsWith("отправитель «"));
    }
}
