package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplLine;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;

class PmtUplRowGateTest {

    @Test
    void identicalCopiesMustMatchInCount() {
        SudzPmtUplLine zero = line("8800576810", null, BigDecimal.ZERO);
        PmtUplRowGate.Verdict verdict = PmtUplRowGate.compare(List.of(zero, zero), List.of(zero));
        assertFalse(verdict.matched());
        assertTrue(verdict.lines().stream().anyMatch(line -> line.contains("нет в базе ×1")));
    }

    @Test
    void extraPaymentIsAGap() {
        SudzPmtUplLine zero = line("5400169793", null, BigDecimal.ZERO);
        PmtUplRowGate.Verdict verdict = PmtUplRowGate.compare(List.of(zero), List.of(zero, zero));
        assertFalse(verdict.matched());
        assertTrue(verdict.lines().stream().anyMatch(line -> line.contains("лишняя в базе ×1")));
    }

    @Test
    void moneyAndZeroWithSameDueStayDistinct() {
        LocalDateTime due = LocalDateTime.of(2025, 12, 31, 0, 0);
        SudzPmtUplLine money = line("8800575763", due, new BigDecimal("-17400660.08"));
        SudzPmtUplLine zero = line("8800575763", due, BigDecimal.ZERO);
        PmtUplRowGate.Verdict verdict = PmtUplRowGate.compare(
                List.of(money, zero), List.of(money, zero));
        assertTrue(verdict.matched());
    }

    private static SudzPmtUplLine line(String doc, LocalDateTime alignment, BigDecimal credit) {
        return new SudzPmtUplLine(
                doc, 1, LocalDateTime.of(2025, 12, 31, 0, 0), alignment,
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
                credit, BigDecimal.ZERO, credit.negate().compareTo(BigDecimal.ZERO) == 0
                        ? BigDecimal.ZERO : credit,
                credit.negate());
    }
}
