package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

/**
 * Сверка Excel ↔ кандидат для шапки decision-TreeList.
 */
class SfDecisionCompareUtilTest {

    @Test
    void invNumSuspiciousBn() {
        assertEquals("suspicious", SfDecisionCompareUtil.invNumVerdict("б/н", "б/н"));
        assertEquals("no", SfDecisionCompareUtil.invNumVerdict("б/н", "94"));
    }

    @Test
    void cnMatchesKs14() {
        assertEquals("yes", SfDecisionCompareUtil.cnVerdict("КС-14", "КС-14"));
        assertEquals("yes", SfDecisionCompareUtil.cnVerdict("кс-14", "КС-14, дата не известна"));
        assertEquals("no", SfDecisionCompareUtil.cnVerdict("КС-14", "КС-51"));
    }

    @Test
    void sumAbsWithinKopeck() {
        assertEquals(
                "yes",
                SfDecisionCompareUtil.sumVerdict(
                        new BigDecimal("-10427623.46"),
                        new BigDecimal("-10427623.46")
                )
        );
        assertEquals(
                "no",
                SfDecisionCompareUtil.sumVerdict(
                        new BigDecimal("-10427623.46"),
                        new BigDecimal("-100.00")
                )
        );
        assertEquals("na", SfDecisionCompareUtil.sumVerdict(null, BigDecimal.ZERO));
    }

    @Test
    void executorBuirg() {
        assertEquals("yes", SfDecisionCompareUtil.executorVerdict(1009345, 1009345));
        assertEquals("no", SfDecisionCompareUtil.executorVerdict(1009315, 1009345));
        assertEquals("na", SfDecisionCompareUtil.executorVerdict(null, 1009345));
        assertEquals("na", SfDecisionCompareUtil.executorVerdict(1009345, null));
    }

    @Test
    void cstSuffixAcrossAgents() {
        assertEquals("001439", SfDecisionCompareUtil.cstCodeSuffix("051-2001439"));
        assertEquals("yes", SfDecisionCompareUtil.cstCodeMatch("051-2001439", "051-2001439"));
        assertEquals(
                "suffix",
                SfDecisionCompareUtil.cstCodeMatch("051-2001439", "062-2001439")
        );
        assertEquals("no", SfDecisionCompareUtil.cstCodeMatch("051-2001439", "051-2002160"));
        assertEquals("na", SfDecisionCompareUtil.cstCodeMatch("051-2001439", null));
        assertEquals(
                "suffix",
                SfDecisionCompareUtil.cstVerdict(
                        "051-2001439",
                        java.util.List.of("062-2001439", "051-2002160")
                )
        );
        assertEquals(
                "yes",
                SfDecisionCompareUtil.cstVerdict(
                        "051-2001439",
                        java.util.List.of("051-2001439", "062-2001439")
                )
        );
        assertEquals(
                "no",
                SfDecisionCompareUtil.cstVerdict(
                        "051-2001439",
                        java.util.List.of("051-2002160")
                )
        );
        assertEquals("na", SfDecisionCompareUtil.cstVerdict("051-2001439", java.util.List.of()));
    }
}
