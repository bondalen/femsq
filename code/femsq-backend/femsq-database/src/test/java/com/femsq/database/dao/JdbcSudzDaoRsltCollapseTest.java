package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzRsltPeriod;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * S77.5: доли одной СФ на upl остаются N строками; L* (разные СФ) по-прежнему 1×upl.
 */
class JdbcSudzDaoRsltCollapseTest {

    @Test
    void sameInvoiceSharesKept() {
        List<SudzRsltPeriod> collapsed = JdbcSudzDao.collapseRsltPeriods(List.of(
                period(910, "2025-12-31", "А45-19974/2024", 0, "36000"),
                period(901, "2026-03-31", "А45-19974/2024", 1, "18000"),
                period(901, "2026-03-31", "А45-19974/2024", 2, "18000")
        ));
        assertEquals(3, collapsed.size());
        assertEquals(1, collapsed.get(1).idNum());
        assertEquals(2, collapsed.get(2).idNum());
        assertEquals(0, new BigDecimal("18000").compareTo(collapsed.get(1).ttl()));
        assertEquals(0, new BigDecimal("18000").compareTo(collapsed.get(2).ttl()));
    }

    @Test
    void differentInvoicesOnOneUplStillCollapsed() {
        List<SudzRsltPeriod> collapsed = JdbcSudzDao.collapseRsltPeriods(List.of(
                period(28, "2025-01-31", "А19-1", 1, "100"),
                period(28, "2025-01-31", "А45-2", 2, "200")
        ));
        assertEquals(1, collapsed.size());
        assertEquals("А19-1", collapsed.get(0).invNumEnum());
    }

    private static SudzRsltPeriod period(int upl, String date, String inv, int idNum, String ttl) {
        LocalDate parsed = LocalDate.parse(date);
        BigDecimal value = new BigDecimal(ttl);
        return new SudzRsltPeriod(
                upl, parsed, parsed, inv, idNum, null, null, null, null, null,
                null, value, value, null, null, null, null);
    }
}
