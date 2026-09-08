package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Правила Split: 2×18000 vs 36000; отказ 1×18000.
 */
class SudzDbtSplitMergeRulesTest {

    @Test
    void twoHalvesMatchCanon() {
        List<SudzDbtSplitPart> parts = List.of(
                part(new BigDecimal("18000")),
                part(new BigDecimal("18000")));
        SudzDbtSplitMergeRules.requireSplitParts(parts);
        SudzDbtSplitMergeRules.requireSplitSum(new BigDecimal("36000"), parts);
        assertTrue(SudzDbtSplitMergeRules.moneyEquals(
                new BigDecimal("36000.00"), new BigDecimal("36000")));
    }

    @Test
    void onePartRejected() {
        assertThrows(IllegalArgumentException.class,
                () -> SudzDbtSplitMergeRules.requireSplitParts(List.of(part(new BigDecimal("36000")))));
    }

    @Test
    void sumMismatchRejected() {
        List<SudzDbtSplitPart> parts = List.of(
                part(new BigDecimal("18000")),
                part(new BigDecimal("17000")));
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> SudzDbtSplitMergeRules.requireSplitSum(new BigDecimal("36000"), parts));
        assertTrue(ex.getMessage().contains("Split"));
    }

    @Test
    void proportionalOverd() {
        BigDecimal overd = SudzDbtSplitMergeRules.splitOverd(
                new BigDecimal("18000"),
                new BigDecimal("36000"),
                new BigDecimal("36000"),
                null);
        assertEquals(0, new BigDecimal("18000.0000").compareTo(overd));
    }

    private static SudzDbtSplitPart part(BigDecimal ttl) {
        return new SudzDbtSplitPart(ttl, null, null, null, null, null, null);
    }
}
