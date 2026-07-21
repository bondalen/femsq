package com.femsq.web.audit.stage2;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты HTML diagnostic Stage 2a type=6 (0055 / 0056).
 */
class AgFeeFkAnomalyFormatterTest {

    @Test
    void formatAgentAnomaliesHtml_empty_returnsNull() {
        assertNull(AgFeeFkAnomalyFormatter.formatAgentAnomaliesHtml(List.of()));
        assertTrue(AgFeeFkAnomalyFormatter.formatAgentTitleHtml(List.of())
                .contains("Все отправители идентифицированы"));
        assertNull(AgFeeFkAnomalyFormatter.formatAgentBodyHtml(List.of()));
    }

    @Test
    void formatAgentAnomaliesHtml_missingAndAmbiguous() {
        String html = AgFeeFkAnomalyFormatter.formatAgentAnomaliesHtml(List.of(
                new AgFeeAgentAnomaly("Газпром инвест", 0),
                new AgFeeAgentAnomaly("Газпром телеком", 2)
        ));
        assertTrue(html.contains("Отсутствуют или неоднозначны отправители"));
        assertTrue(html.contains("Газпром инвест"));
        assertTrue(html.contains("не найден"));
        assertTrue(html.contains("ключей=2"));
        assertTrue(html.contains("Crimson"));
    }

    @Test
    void formatCstAnomaliesHtml_empty_returnsNull() {
        assertNull(AgFeeFkAnomalyFormatter.formatCstAnomaliesHtml(List.of()));
        assertTrue(AgFeeFkAnomalyFormatter.formatCstTitleHtml(List.of())
                .contains("отсутствуют стройки, отсутствующие в БД"));
        assertNull(AgFeeFkAnomalyFormatter.formatCstBodyHtml(List.of()));
    }

    @Test
    void formatCstAnomaliesHtml_groupsByCodeWithExcelRows() {
        String title = AgFeeFkAnomalyFormatter.formatCstTitleHtml(List.of(
                new AgFeeCstAnomaly("999-0000001", List.of(10, 12, 15), 3)
        ));
        String body = AgFeeFkAnomalyFormatter.formatCstBodyHtml(List.of(
                new AgFeeCstAnomaly("999-0000001", List.of(10, 12, 15), 3)
        ));
        assertTrue(title.contains("стройки, отсутствующие в БД"));
        assertTrue(title.contains("1</font></b>"));
        assertTrue(body.contains("999-0000001"));
        assertTrue(body.contains("строки Excel 10, 12, 15"));
        assertTrue(body.contains("стройка"));
        assertEquals(true, body.contains("<b>1</b>"));
    }

    @Test
    void formatExcelRows_singleAndEmpty() {
        assertTrue(AgFeeFkAnomalyFormatter.formatExcelRows(List.of(42), 1).contains("строка Excel 42"));
        assertTrue(AgFeeFkAnomalyFormatter.formatExcelRows(List.of(), 5)
                .contains("упоминаний в файле: 5"));
    }
}
