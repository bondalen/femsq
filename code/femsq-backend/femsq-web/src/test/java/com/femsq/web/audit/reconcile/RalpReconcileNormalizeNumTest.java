package com.femsq.web.audit.reconcile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

/**
 * Unit-тесты {@link RalpReconcileService#normalizeNum} (задача 0064).
 */
class RalpReconcileNormalizeNumTest {

    @Test
    void matchesDomain480WithStaging480comma() {
        assertEquals("480", RalpReconcileService.normalizeNum("480,00", true));
        assertEquals("480", RalpReconcileService.normalizeNum("480", true));
    }

    @Test
    void presentedReplacesDashAfterFractionStrip() {
        assertEquals("480/310326", RalpReconcileService.normalizeNum("480-310326", true));
        assertEquals("480-310326", RalpReconcileService.normalizeNum("480-310326", false));
    }

    @Test
    void slashFormUnchanged() {
        assertEquals("480/310326", RalpReconcileService.normalizeNum("480/310326", true));
    }

    @Test
    void nullSafe() {
        assertNull(RalpReconcileService.normalizeNum(null, true));
    }
}
