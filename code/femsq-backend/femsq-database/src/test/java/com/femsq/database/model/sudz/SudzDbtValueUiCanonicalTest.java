package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class SudzDbtValueUiCanonicalTest {

    @Test
    void pitRangeRecognized() {
        assertTrue(SudzDbtValueUiCanonical.isPitUpl(801));
        assertTrue(SudzDbtValueUiCanonical.isPitUpl(899));
        assertTrue(SudzDbtValueUiCanonical.isPitUpl(903));
        assertTrue(SudzDbtValueUiCanonical.isPitUpl(909));
        assertFalse(SudzDbtValueUiCanonical.isPitUpl(800));
        assertFalse(SudzDbtValueUiCanonical.isPitUpl(910));
        assertFalse(SudzDbtValueUiCanonical.isPitUpl(26));
        assertFalse(SudzDbtValueUiCanonical.isPitUpl(null));
    }

    @Test
    void dropsPitAndDedupsSameAsOfPreferringHigherUpl() {
        List<SudzInvDbtTimelinePoint> raw = List.of(
                point(26, "2024-12-31", 2002.23),
                point(801, "2024-12-31", 2002.23),
                point(27, "2025-03-31", 1701.90),
                point(802, "2025-03-31", 1701.90),
                point(901, "2025-12-31", 800.91),
                point(910, "2025-12-31", 800.91),
                point(903, "2026-06-30", 200.23)
        );
        List<SudzInvDbtTimelinePoint> out = SudzDbtValueUiCanonical.canonicalize(raw);
        assertEquals(3, out.size());
        assertEquals(26, out.get(0).uplKey());
        assertEquals(27, out.get(1).uplKey());
        assertEquals(910, out.get(2).uplKey());
    }

    @Test
    void dropsUndated() {
        List<SudzInvDbtTimelinePoint> out = SudzDbtValueUiCanonical.canonicalize(List.of(
                new SudzInvDbtTimelinePoint(15, null, BigDecimal.ONE, null, "dbtValue", 1)
        ));
        assertTrue(out.isEmpty());
    }

    private static SudzInvDbtTimelinePoint point(int upl, String date, double ttl) {
        return new SudzInvDbtTimelinePoint(
                upl,
                LocalDate.parse(date),
                BigDecimal.valueOf(ttl),
                null,
                "dbtValue",
                10549
        );
    }
}
