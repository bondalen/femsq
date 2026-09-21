package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Префикс панели воронки платежей: excelToTbl не в цепочке чекбоксов.
 */
class SudzPmtUplFunnelStepsTest {

    @Test
    void emptyPrefixAllowed() {
        assertDoesNotThrow(() -> SudzPmtUplFunnelSteps.requirePrefixOfEnabled(List.of()));
    }

    @Test
    void firstEnabledIsCtpt() {
        assertDoesNotThrow(() -> SudzPmtUplFunnelSteps.requirePrefixOfEnabled(
                List.of("cipuCtpt_All_OIdNot")));
    }

    @Test
    void excelToTblIsNotInPanelChain() {
        assertThrows(IllegalArgumentException.class,
                () -> SudzPmtUplFunnelSteps.requirePrefixOfEnabled(List.of("excelToTbl")));
    }

    @Test
    void enabledChainHasThirteenSteps() {
        assertEquals(13, SudzPmtUplFunnelSteps.enabledIds().size());
    }

    @Test
    void fullPrefixAllowed() {
        assertDoesNotThrow(() -> SudzPmtUplFunnelSteps.requirePrefixOfEnabled(
                SudzPmtUplFunnelSteps.enabledIds()));
    }

    @Test
    void singleInsPmNotLoadRetryAllowed() {
        assertDoesNotThrow(() -> SudzPmtUplFunnelSteps.requirePrefixOfEnabled(
                List.of("cipuInsPmNotLoad")));
        assertTrue(SudzPmtUplFunnelSteps.isSingleTailRetry(List.of("cipuInsPmNotLoad")));
    }
}
