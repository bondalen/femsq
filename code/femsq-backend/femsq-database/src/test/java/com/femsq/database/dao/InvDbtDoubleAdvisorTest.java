package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzInvDbtTimelinePoint;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Smoke-тесты эвристик советника КСДД.
 */
class InvDbtDoubleAdvisorTest {

    @Test
    void amortization329StyleTail() {
        List<SudzInvDbtTimelinePoint> points = List.of(
                point("2024-01-30", 96742.08),
                point("2024-04-19", 88449.87),
                point("2024-07-19", 80157.66),
                point("2024-10-21", 71865.45),
                point("2025-01-24", 63573.24),
                point("2025-04-21", 55281.03),
                point("2025-07-18", 46988.82)
        );
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                1, 1, null, 910, 329, null, null, new BigDecimal("30404.40"),
                6766, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("30404.40"), null, null, null, null, null, 910);
        var slot = new com.femsq.database.model.sudz.SudzInvDbtSlot(42, 329, 1, "ciaName=1");
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                List.of(slot),
                java.util.Map.of(42, 23),
                java.util.Map.of(42, 6766),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(42, points),
                LocalDate.parse("2025-12-31"),
                new BigDecimal("0.01"));
        assertTrue(advice.messageText().contains("[советник]"));
        assertTrue(advice.messageText().contains("Связать со слотом 42"));
        assertTrue("high".equals(advice.confidence()) || "medium".equals(advice.confidence()));
    }

    private static SudzInvDbtTimelinePoint point(String date, double ttl) {
        return new SudzInvDbtTimelinePoint(
                null,
                LocalDate.parse(date),
                BigDecimal.valueOf(ttl),
                BigDecimal.ZERO,
                "dbtValue",
                6766);
    }
}
