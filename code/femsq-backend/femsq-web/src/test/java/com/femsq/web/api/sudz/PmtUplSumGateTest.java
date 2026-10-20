package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplSum;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Сверка сумм книги и базы в конце воронки платежей.
 */
class PmtUplSumGateTest {

    @Test
    void emptyBookIsNotOk() {
        PmtUplSumGate.Verdict verdict = PmtUplSumGate.compare(List.of(), List.of(row(null, "1.00")));
        assertFalse(verdict.matched());
    }

    @Test
    void matchWithinEpsilonIncludingTotal() {
        SudzPmtUplSum book = row(767501, "100.00", "40.00", "60.00", "10.00", "3.00", "7.00", "-90.00");
        SudzPmtUplSum db = row(767501, "100.005", "40.00", "60.00", "10.00", "3.00", "7.00", "-90.00");
        SudzPmtUplSum total = row(null, "100.00", "40.00", "60.00", "10.00", "3.00", "7.00", "-90.00");
        PmtUplSumGate.Verdict verdict = PmtUplSumGate.compare(List.of(book), List.of(db, total));
        assertTrue(verdict.matched());
    }

    @Test
    void overdueMismatchIsNotOk() {
        SudzPmtUplSum book = row(767501, "0", "1.51", "0", "0", "0", "0", "0");
        SudzPmtUplSum db = row(767501, "0", "0", "0", "0", "0", "0", "0");
        SudzPmtUplSum total = row(null, "0", "0", "0", "0", "0", "0", "0");
        PmtUplSumGate.Verdict verdict = PmtUplSumGate.compare(List.of(book), List.of(db, total));
        assertFalse(verdict.matched());
        assertTrue(verdict.lines().stream().anyMatch(line -> line.contains("дебет проср.")));
    }

    @Test
    void totalMismatchIsNotOk() {
        SudzPmtUplSum book = row(767501, "10.00");
        SudzPmtUplSum db = row(767501, "10.00");
        SudzPmtUplSum total = row(null, "9.00");
        PmtUplSumGate.Verdict verdict = PmtUplSumGate.compare(List.of(book), List.of(db, total));
        assertFalse(verdict.matched());
        assertTrue(verdict.lines().stream().anyMatch(line -> line.startsWith("итого")));
    }

    private static SudzPmtUplSum row(Integer account, String dbt) {
        return row(account, dbt, "0", "0", "0", "0", "0", "0");
    }

    private static SudzPmtUplSum row(
            Integer account,
            String dbt,
            String dbtOverd,
            String dbtNot,
            String cdt,
            String cdtOverd,
            String cdtNot,
            String blns
    ) {
        return new SudzPmtUplSum(
                1,
                account,
                new BigDecimal(dbt),
                new BigDecimal(dbtOverd),
                new BigDecimal(dbtNot),
                new BigDecimal(cdt),
                new BigDecimal(cdtOverd),
                new BigDecimal(cdtNot),
                new BigDecimal(blns));
    }
}
