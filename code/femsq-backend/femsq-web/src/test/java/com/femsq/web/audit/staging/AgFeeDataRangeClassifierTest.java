package com.femsq.web.audit.staging;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * Unit-тесты критерия диапазона Stage 1 type=6 (0056).
 */
class AgFeeDataRangeClassifierTest {

    @Test
    void significant_whenActAndCst() {
        assertTrue(AgFeeDataRangeClassifier.isSignificantValues("13ДС", "051-2000896", false));
    }

    @Test
    void significant_whenActAndExcelDateWithoutCst() {
        assertTrue(AgFeeDataRangeClassifier.isSignificantValues("1РЧС", null, true));
    }

    @Test
    void notSignificant_junkCounterRowWithoutCstOrDate() {
        // хвост UsedRange: № Акта=665, Дата=665 (не date-format), без кода стройки
        assertFalse(AgFeeDataRangeClassifier.isSignificantValues("665", null, false));
        assertFalse(AgFeeDataRangeClassifier.isSignificantValues("665", "  ", false));
    }

    @Test
    void notSignificant_blankAct() {
        assertFalse(AgFeeDataRangeClassifier.isSignificantValues(null, "051-1", true));
        assertFalse(AgFeeDataRangeClassifier.isSignificantValues("  ", "051-1", true));
    }
}
