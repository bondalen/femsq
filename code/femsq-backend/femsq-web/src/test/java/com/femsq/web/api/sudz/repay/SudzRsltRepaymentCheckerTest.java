package com.femsq.web.api.sudz.repay;

import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Классы «Проверить погашения» на синтетических срезах.
 */
class SudzRsltRepaymentCheckerTest {

    @Test
    void partialReduceWithoutForeignTwinIsLikelyTrue() {
        SudzRsltDebt debt = debt(1, "76",
                period(901, "2025-01-01", "100", "100", "100"),
                period(903, "2025-12-01", "100", "40", "40"));
        SudzRsltRepaymentCheck check = SudzRsltRepaymentChecker.check(901, 903, List.of(debt));
        assertEquals(1, check.candidateCount());
        assertEquals(1, check.likelyTrueCount());
        assertEquals(0, check.suspectCount());
        assertTrue(check.openCases().isEmpty());
    }

    @Test
    void oneForeignTwinIsSuspect() {
        SudzRsltDebt reduced = debt(1, "76",
                period(901, "2025-01-01", "100", "100", "100"),
                period(903, "2025-12-01", "100", "40", "40"));
        SudzRsltDebt twin = debt(2, "76",
                period(901, "2025-01-01", "200", "999", "60"),
                period(903, "2025-12-01", "200", "999", "60"));
        SudzRsltRepaymentCheck check = SudzRsltRepaymentChecker.check(901, 903, List.of(reduced, twin));
        assertEquals(1, check.suspectCount());
        assertEquals("suspect", check.openCases().get(0).clazz());
        assertEquals("partial_reduce_but_foreign_twin", check.openCases().get(0).reason());
    }

    @Test
    void twoForeignTwinsAreAmbiguous() {
        SudzRsltDebt reduced = debt(1, "76",
                period(901, "2025-01-01", "100", "100", "100"),
                period(903, "2025-12-01", "100", "40", "40"));
        SudzRsltDebt twinA = debt(2, "76",
                period(902, "2025-06-01", "201", "60", "60"));
        SudzRsltDebt twinB = debt(3, "76",
                period(902, "2025-06-01", "202", "60", "60"));
        SudzRsltRepaymentCheck check = SudzRsltRepaymentChecker.check(901, 903, List.of(reduced, twinA, twinB));
        assertEquals(1, check.ambiguousCount());
        assertEquals(0, check.suspectCount());
        assertEquals("ambiguous", check.openCases().get(0).clazz());
    }

    @Test
    void documentedInvoiceIsNotASuspect() {
        SudzRsltDebt debt = debt(1, "76",
                period(901, "2025-01-01", "86740", "100", "100"),
                period(903, "2025-12-01", "86740", null, null));
        SudzRsltRepaymentCheck check = SudzRsltRepaymentChecker.check(901, 903, List.of(debt));
        assertEquals(1, check.documentedCount());
        assertEquals(0, check.suspectCount());
        assertTrue(check.openCases().isEmpty());
    }

    @Test
    void qiiiParallelTwin52262IsDocumentedNotSuspect() {
        SudzRsltDebt gone = debt(7757, "606012",
                period(901, "2026-01-15", "52262", "10000000", "10000000"),
                period(916, "2026-09-30", "52262", null, null));
        SudzRsltDebt parallel = debt(12067, "762210",
                period(901, "2026-01-15", "25/76", "10000000", "10000000"),
                period(916, "2026-09-30", "25/76", "10000000", "10000000"));
        SudzRsltRepaymentCheck check = SudzRsltRepaymentChecker.check(901, 916, List.of(gone, parallel));
        assertEquals(1, check.documentedCount());
        assertEquals(0, check.suspectCount());
        assertTrue(check.openCases().stream().noneMatch(c -> c.dbtKey() == 7757));
    }

    private static SudzRsltDebt debt(int key, String account, SudzRsltPeriod... periods) {
        return new SudzRsltDebt(key, account, null, null, null, null, null, null, null, List.of(periods));
    }

    private static SudzRsltPeriod period(int upl, String date, String inv, String ttl, String overd) {
        return new SudzRsltPeriod(
                upl,
                LocalDate.parse(date),
                LocalDate.parse(date),
                inv,
                0,
                "Д-1",
                null,
                null,
                null,
                null,
                null,
                dec(ttl),
                dec(overd),
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null);
    }

    private static BigDecimal dec(String value) {
        return value == null ? null : new BigDecimal(value);
    }
}
