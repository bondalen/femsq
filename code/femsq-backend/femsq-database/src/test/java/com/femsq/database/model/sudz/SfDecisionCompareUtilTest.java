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
    void invNumMatchesAnyAlias() {
        assertEquals(
                "yes",
                SfDecisionCompareUtil.invNumVerdict(
                        "0818 CR 0096/AA01/",
                        java.util.List.of("0818 CR 0096/AA01/ (номеров: 2)", "0818 CR 0096/AA01/")
                )
        );
        assertEquals(
                "no",
                SfDecisionCompareUtil.invNumVerdict("94", java.util.List.of("93", "92"))
        );
        assertEquals(
                "suspicious",
                SfDecisionCompareUtil.invNumVerdict("б/н", java.util.List.of("б/н", "94"))
        );
    }

    @Test
    void docTransferChip() {
        assertEquals("transfer", SfDecisionCompareUtil.docTransferVerdict(true));
        assertEquals("na", SfDecisionCompareUtil.docTransferVerdict(false));
    }

    @Test
    void cnMatchesKs14() {
        assertEquals("yes", SfDecisionCompareUtil.cnVerdict("КС-14", "КС-14"));
        assertEquals("yes", SfDecisionCompareUtil.cnVerdict("кс-14", "КС-14, дата не известна"));
        assertEquals("no", SfDecisionCompareUtil.cnVerdict("КС-14", "КС-51"));
        assertEquals(
                "yes",
                SfDecisionCompareUtil.cnVerdict("КС-51", java.util.List.of("КС-01", "КС-51"))
        );
        assertEquals(
                "no",
                SfDecisionCompareUtil.cnVerdict("КС-51", java.util.List.of("КС-01", "2657"))
        );
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

    @Test
    void cstPackageVsHistory() {
        assertEquals(
                "yes",
                SfDecisionCompareUtil.cstVerdict(
                        "051-2001439",
                        java.util.List.of("051-2001439")
                )
        );
        assertEquals(
                "other",
                SfDecisionCompareUtil.cstHistVerdict(
                        "051-2001439",
                        java.util.List.of("051-2002339")
                )
        );
        assertEquals(
                "na",
                SfDecisionCompareUtil.cstHistVerdict(
                        "051-2001439",
                        java.util.List.of("051-2001439", "062-2001439")
                )
        );
        assertEquals("na", SfDecisionCompareUtil.cstHistVerdict("051-2001439", java.util.List.of()));
        SudzSfDecisionCompare cmp = SfDecisionCompareUtil.build(
                "88",
                "88",
                "КС-51",
                java.util.List.of("КС-51"),
                1009345,
                1009345,
                new BigDecimal("-631200.16"),
                new BigDecimal("-631200.16"),
                "051-2001439",
                java.util.List.of("051-2001439"),
                java.util.List.of("051-2002339")
        );
        assertEquals("yes", cmp.cstVerdict());
        assertEquals("other", cmp.cstHistVerdict());
    }
}
