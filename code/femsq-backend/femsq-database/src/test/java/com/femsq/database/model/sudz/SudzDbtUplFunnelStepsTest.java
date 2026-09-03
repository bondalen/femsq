package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Префикс панели воронки: Excel→Tbl не в цепочке чекбоксов; S66e — invDbt*.
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

    @Test
    void enabledChainEndsWithDbtValueLoadAfterInvDbtDbtEnsure() {
        List<String> chain = SudzDbtUplFunnelSteps.enabledIds();
        assertEquals(SudzDbtUplFunnelSteps.INV_DBT_DBT_ENSURE, chain.get(chain.size() - 2));
        assertEquals(SudzDbtUplFunnelSteps.DBT_VALUE_LOAD, chain.get(chain.size() - 1));
    }

    @Test
    void enabledChainEndsWithInvDbtLoadAfterAccSmpl() {
        List<String> chain = SudzDbtUplFunnelSteps.enabledIds();
        assertTrue(chain.size() >= 2);
        int accSmpl = chain.indexOf(SudzDbtUplFunnelSteps.CN_CTPT_INV_EXIST_ACC_SMPL_NOT_LOAD);
        assertTrue(accSmpl >= 0);
        assertEquals(SudzDbtUplFunnelSteps.INV_DBT_VAR_ENSURE, chain.get(accSmpl + 1));
        assertEquals(SudzDbtUplFunnelSteps.INV_DBT_LOAD, chain.get(accSmpl + 2));
    }

    @Test
    void accessTailDisabled() {
        assertDoesNotThrow(() -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(
                SudzDbtUplFunnelSteps.enabledIds()));
        assertThrows(IllegalArgumentException.class,
                () -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(List.of("invDbtDouble")));
    }

    @Test
    void singleDbtValueLoadRetryAllowed() {
        assertDoesNotThrow(() -> SudzDbtUplFunnelSteps.requirePrefixOfEnabled(
                List.of(SudzDbtUplFunnelSteps.DBT_VALUE_LOAD)));
    }
}
