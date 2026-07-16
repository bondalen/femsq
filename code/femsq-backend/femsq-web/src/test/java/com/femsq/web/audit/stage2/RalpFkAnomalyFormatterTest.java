package com.femsq.web.audit.stage2;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты текстов аномалий Stage 2 RALP (0051 / §9.3.6.3).
 */
class RalpFkAnomalyFormatterTest {

    @Test
    void reasonLines_A1_emptyAndMalformedCst() {
        assertEquals(
                List.of("код стройки пуст"),
                RalpFkAnomalyFormatter.reasonLines(row(null, LocalDate.of(2026, 1, 1), "", null, null, 1))
        );
        assertEquals(
                List.of("стройка не найдена: «ABC»"),
                RalpFkAnomalyFormatter.reasonLines(row(null, LocalDate.of(2026, 1, 1), "ABC", null, null, 1))
        );
    }

    @Test
    void reasonLines_A2_cstMissingInDb() {
        assertEquals(
                List.of("стройка «026-3005711» в БД отсутствует"),
                RalpFkAnomalyFormatter.reasonLines(row(null, LocalDate.of(2026, 1, 31), "026-3005711", null, null, 3))
        );
    }

    @Test
    void reasonLines_A3_dateMissing() {
        assertEquals(
                List.of("дата отсутствует"),
                RalpFkAnomalyFormatter.reasonLines(row(null, null, null, null, 1, 1))
        );
    }

    @Test
    void reasonLines_A4_senderWithAndWithoutBranch() {
        assertEquals(
                List.of("отправитель в БД отсутствует, или их несколько: «Газпром инвест»"),
                RalpFkAnomalyFormatter.reasonLines(
                        row(null, LocalDate.of(2026, 2, 28), null, "Газпром инвест", 1, null)
                )
        );
        assertEquals(
                List.of("филиал-отправитель в БД отсутствует, или их несколько: «Газпром инвест» / «Газпром Ремонт»"),
                RalpFkAnomalyFormatter.reasonLines(
                        new RalpFkAnomalyRow(
                                1L, 10, "137/310126", LocalDate.of(2026, 1, 31),
                                "051-2006349", "Газпром инвест", "Газпром Ремонт", 4257, null
                        )
                )
        );
    }

    @Test
    void formatWarningHtml_includesExcelRowAndReasons() {
        RalpFkAnomalyRow row = new RalpFkAnomalyRow(
                28099L,
                42,
                "0126/310126",
                LocalDate.of(2026, 1, 31),
                "026-3005711",
                "Газпром добыча Оренбург",
                "Газпром добыча Оренбург",
                null,
                null
        );
        String html = RalpFkAnomalyFormatter.formatWarningHtml(row, "Аренда_Земли");
        assertTrue(html.contains("Excel-строка"));
        assertTrue(html.contains("femsq-anomaly-ref"));
        assertTrue(html.contains(">42</span>"));
        assertTrue(html.contains("лист «Аренда_Земли»"));
        assertTrue(html.contains("0126/310126"));
        assertTrue(html.contains("femsq-anomaly-val"));
        assertTrue(html.contains("026-3005711"));
        assertTrue(html.contains("филиал-отправитель"));
        assertTrue(html.contains("некорректная"));
    }

    @Test
    void formatStage2SummaryHtml_includesUnresolvedCounters() {
        String html = RalpFkAnomalyFormatter.formatStage2SummaryHtml(420, 421, 0, 424, 424, 4, 2, 3, 0);
        assertTrue(html.contains("промежуточная таблица = 424"));
        assertTrue(html.contains("неразрешённых строк = 4"));
        assertTrue(html.contains("стройка NULL = 2"));
        assertTrue(html.contains("отправитель NULL = 3"));
    }

    private static RalpFkAnomalyRow row(
            Integer excelRow,
            LocalDate date,
            String cst,
            String sender,
            Integer cstKey,
            Integer ogKey
    ) {
        return new RalpFkAnomalyRow(1L, excelRow, "X", date, cst, sender, null, cstKey, ogKey);
    }
}
