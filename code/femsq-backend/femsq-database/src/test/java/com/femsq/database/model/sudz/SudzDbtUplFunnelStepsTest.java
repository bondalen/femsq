package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Префикс панели воронки: Excel→Tbl не в цепочке чекбоксов.
 */
class SudzDbtUplFunnelStepsTest {

    @Test
    void emptyPrefixAllowed() {
        assertDoesNotThrow(() -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(List.of()));
    }

    @Test
    void orgIsFirstEnabled() {
        assertDoesNotThrow(() -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(
                List.of(SudzDbtUplFunnelSteps.ORG_NOT_IN_BUIRG)));
    }

    @Test
    void excelToTblIsNotInPanelChain() {
        assertThrows(IllegalArgumentException.class,
                () -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(List.of("excelToTbl")));
    }
}
