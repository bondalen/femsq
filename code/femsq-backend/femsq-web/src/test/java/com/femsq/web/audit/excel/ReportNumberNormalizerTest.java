package com.femsq.web.audit.excel;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

/**
 * Unit-тесты канона номера отчёта (0064 / false orphan {@code 480} vs {@code 480,00}).
 */
class ReportNumberNormalizerTest {

    @Test
    void stripsZeroFractionComma() {
        assertEquals("480", ReportNumberNormalizer.normalize("480,00"));
    }

    @Test
    void stripsZeroFractionDot() {
        assertEquals("480", ReportNumberNormalizer.normalize("480.00"));
    }

    @Test
    void keepsBareInteger() {
        assertEquals("480", ReportNumberNormalizer.normalize("480"));
    }

    @Test
    void keepsSlashForm() {
        assertEquals("480/310326", ReportNumberNormalizer.normalize("480/310326"));
    }

    @Test
    void keepsNonZeroFraction() {
        assertEquals("480,50", ReportNumberNormalizer.normalize("480,50"));
    }

    @Test
    void keepsSuffixText() {
        assertEquals("1011/300626 кор", ReportNumberNormalizer.normalize("1011/300626 кор"));
    }

    @Test
    void nullAndBlank() {
        assertNull(ReportNumberNormalizer.normalize(null));
        assertNull(ReportNumberNormalizer.normalize("  "));
    }
}
