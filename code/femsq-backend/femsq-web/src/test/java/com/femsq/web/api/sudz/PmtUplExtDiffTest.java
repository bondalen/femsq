package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplExtDiff;
import com.femsq.database.model.sudz.SudzPmtUplExtLine;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Сверка InsPmExt: суммы совпали, код стройки в базе пустой.
 */
class PmtUplExtDiffTest {

    @Test
    void siteGapWhenMoneyMatches() {
        SudzPmtUplExtDiff diff = PmtUplExtDiff.compare(
                List.of(line("5400", "014-2007423")),
                List.of(line("5400", null)));
        assertEquals(1, diff.gapCount());
        assertEquals("стройка", diff.gaps().get(0).field());
        assertEquals("014-2007423", diff.gaps().get(0).bookValue());
        assertEquals(null, diff.gaps().get(0).dbValue());
    }

    @Test
    void emptyWhenSiteAndMoneyMatch() {
        SudzPmtUplExtDiff diff = PmtUplExtDiff.compare(
                List.of(line("5400", "014-2007423")),
                List.of(line("5400", "014-2007423")));
        assertEquals(0, diff.gapCount());
        assertTrue(diff.gaps().isEmpty());
    }

    @Test
    void extraBookRowIsALineGap() {
        SudzPmtUplExtDiff diff = PmtUplExtDiff.compare(
                List.of(line("5400", null), line("5401", null)),
                List.of(line("5400", null)));
        assertEquals(1, diff.gapCount());
        assertEquals("строка", diff.gaps().get(0).field());
        assertEquals("5401", diff.gaps().get(0).docCode());
        assertEquals("есть", diff.gaps().get(0).bookValue());
        assertEquals("нет", diff.gaps().get(0).dbValue());
    }

    private static SudzPmtUplExtLine line(String doc, String cac) {
        return new SudzPmtUplExtLine(
                doc,
                1,
                LocalDateTime.of(2026, 1, 30, 0, 0),
                null,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                cac);
    }
}
