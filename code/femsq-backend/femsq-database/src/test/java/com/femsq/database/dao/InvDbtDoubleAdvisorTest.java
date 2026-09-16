package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzInvDbtTimelinePoint;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Smoke-тесты эвристик советника КСДД.
 */
class InvDbtDoubleAdvisorTest {

    @Test
    void amortization329StyleTail() {
        List<SudzInvDbtTimelinePoint> points = List.of(
                point("2024-01-30", 96742.08),
                point("2024-04-19", 88449.87),
                point("2024-07-19", 80157.66),
                point("2024-10-21", 71865.45),
                point("2025-01-24", 63573.24),
                point("2025-04-21", 55281.03),
                point("2025-07-18", 46988.82)
        );
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                1, 1, null, 910, 329, null, null, new BigDecimal("30404.40"),
                6766, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("30404.40"), null, null, null, null, null, 910);
        var slot = new com.femsq.database.model.sudz.SudzInvDbtSlot(42, 329, 1, "ciaName=1");
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                List.of(slot),
                java.util.Map.of(42, 23),
                java.util.Map.of(42, 6766),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(42, points),
                LocalDate.parse("2025-12-31"),
                new BigDecimal("0.01"));
        assertTrue(advice.messageText().contains("[советник]"));
        assertTrue(advice.messageText().contains("Связать со слотом 42"));
        assertTrue("high".equals(advice.confidence()) || "medium".equals(advice.confidence()));
        assertEquals("link", advice.action());
    }

    @Test
    void splitWhenSiblingSumEqualsSlotAndSharesDiffer() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                2807, 1, null, 901, 85166, null, null, new BigDecimal("18000"),
                1, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(2807, new BigDecimal("18000"), null, 1),
                new InvDbtDoubleAdvisor.OpenShare(2808, new BigDecimal("18000"), null, 1)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(11897, 99, new BigDecimal("36000"), 1)
        );
        var split = InvDbtDoubleAdvisor.detectSplit(
                row, shares, canons, 901, new BigDecimal("0.01"));
        assertTrue(split.isPresent());
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("18000"), null, null, null, null, null, 901);
        var slot = new com.femsq.database.model.sudz.SudzInvDbtSlot(11897, 85166, 1, "ciaName=1");
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                List.of(slot),
                java.util.Map.of(11897, 23),
                java.util.Map.of(11897, 1),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2025-12-31"),
                new BigDecimal("0.01"),
                split);
        assertEquals("split", advice.action());
        assertEquals(11897, advice.recommendIdKey());
        assertEquals(99, advice.recommendDbtKey());
        assertTrue(advice.messageText().contains("не Link"));
        assertEquals(2, advice.splitParts().size());
    }

    @Test
    void noSplitWhenShareEqualsWholeSlot() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                1, 1, null, 901, 10, null, null, new BigDecimal("36000"),
                1, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(1, new BigDecimal("36000"), null, 1)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(5, 9, new BigDecimal("36000"), 1)
        );
        assertTrue(InvDbtDoubleAdvisor.detectSplit(
                row, shares, canons, 901, new BigDecimal("0.01")).isEmpty());
    }

    @Test
    void noSplitWhenShareSlotsAlreadyExist() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3795, 1, null, 902, 85166, null, null, new BigDecimal("18000"),
                15629, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(3795, new BigDecimal("18000"), null, 15629),
                new InvDbtDoubleAdvisor.OpenShare(3796, new BigDecimal("18000"), null, 15629)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(11897, 11897, new BigDecimal("36000"), 1064),
                new InvDbtDoubleAdvisor.SlotCanon(13041, 11897, new BigDecimal("18000"), 15629),
                new InvDbtDoubleAdvisor.SlotCanon(13042, 11897, new BigDecimal("18000"), 15629)
        );
        assertTrue(InvDbtDoubleAdvisor.detectSplit(
                row, shares, canons, 902, new BigDecimal("0.01")).isEmpty());
    }

    @Test
    void linkWhenShareSlotsAlreadyExist() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3795, 1, null, 902, 85166, "32-426/05-18", "А45-19974/2024",
                new BigDecimal("18000"),
                15629, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(3795, new BigDecimal("18000"), null, 15629),
                new InvDbtDoubleAdvisor.OpenShare(3796, new BigDecimal("18000"), null, 15629)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(11897, 11897, new BigDecimal("36000"), 1064),
                new InvDbtDoubleAdvisor.SlotCanon(13041, 11897, new BigDecimal("18000"), 15629),
                new InvDbtDoubleAdvisor.SlotCanon(13042, 11897, new BigDecimal("18000"), 15629)
        );
        assertTrue(InvDbtDoubleAdvisor.detectSplit(
                row, shares, canons, 902, new BigDecimal("0.01")).isEmpty());
        var shareLink = InvDbtDoubleAdvisor.findExistingShareLink(
                row, shares, canons, new BigDecimal("0.01"));
        assertEquals(Optional.of(13041), shareLink);

        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("18000"), null, null, null, null, null, 902);
        var slots = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtSlot(11897, 85166, 0, null),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13041, 85166, 1, "S77-split-1"),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13042, 85166, 2, "S77-split-2")
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                java.util.Map.of(11897, 23, 13041, 23, 13042, 23),
                java.util.Map.of(11897, 1064, 13041, 15629, 13042, 15629),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                shareLink);
        assertEquals("link", advice.action());
        assertEquals(13041, advice.recommendIdKey());
        assertEquals("high", advice.confidence());
        assertTrue(advice.messageText().contains("Split не нужен"));
        assertTrue(advice.messageText().contains("Связать со слотом 13041"));
    }

    @Test
    void linkSecondShareWhenSlotsAlreadyExist() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3796, 1, null, 902, 85166, "32-425/05-18", "А45-19974/2024",
                new BigDecimal("18000"),
                15629, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(3795, new BigDecimal("18000"), null, 15629),
                new InvDbtDoubleAdvisor.OpenShare(3796, new BigDecimal("18000"), null, 15629)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(11897, 11897, new BigDecimal("36000"), 1064),
                new InvDbtDoubleAdvisor.SlotCanon(13041, 11897, new BigDecimal("18000"), 15629),
                new InvDbtDoubleAdvisor.SlotCanon(13042, 11897, new BigDecimal("18000"), 15629)
        );
        var shareLink = InvDbtDoubleAdvisor.findExistingShareLink(
                row, shares, canons, new BigDecimal("0.01"));
        assertEquals(Optional.of(13042), shareLink);
    }

    @Test
    void linkSecondShareSkipsAlreadyLinkedSlot() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3796, 1, null, 902, 85166, "32-425/05-18", "А45-19974/2024",
                new BigDecimal("18000"),
                15629, "multi", null, "open", null, null);
        var shares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(
                        3795, new BigDecimal("18000"), null, 15629, 13041),
                new InvDbtDoubleAdvisor.OpenShare(
                        3796, new BigDecimal("18000"), null, 15629, null)
        );
        var canons = List.of(
                new InvDbtDoubleAdvisor.SlotCanon(11897, 11897, new BigDecimal("36000"), 1064),
                new InvDbtDoubleAdvisor.SlotCanon(13041, 11897, new BigDecimal("18000"), 15629),
                new InvDbtDoubleAdvisor.SlotCanon(13042, 11897, new BigDecimal("18000"), 15629)
        );
        assertTrue(InvDbtDoubleAdvisor.detectSplit(
                row,
                List.of(new InvDbtDoubleAdvisor.OpenShare(
                        3796, new BigDecimal("18000"), null, 15629)),
                canons,
                902,
                new BigDecimal("0.01")).isEmpty());
        var shareLink = InvDbtDoubleAdvisor.findExistingShareLink(
                row, shares, canons, new BigDecimal("0.01"));
        assertEquals(Optional.of(13042), shareLink);

        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("18000"), null, null, null, null, null, 902);
        var slots = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtSlot(11897, 85166, 0, null),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13041, 85166, 1, "S77-split-1"),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13042, 85166, 2, "S77-split-2")
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                java.util.Map.of(11897, 23, 13041, 23, 13042, 23),
                java.util.Map.of(11897, 1064, 13041, 15629, 13042, 15629),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                shareLink);
        assertEquals("link", advice.action());
        assertEquals(13042, advice.recommendIdKey());
        assertTrue(advice.messageText().contains("13042"));
    }

    @Test
    void linkedRowKeepsCreatedSlotNotBridgeFirst() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3796, 1, null, 902, 85166, "32-425/05-18", "А45-19974/2024",
                new BigDecimal("18000"),
                15629, "multi", null, "created", null, 13042);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 24, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("18000"), null, null, null, null, null, 902);
        var slots = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtSlot(11897, 85166, 0, null),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13041, 85166, 1, "S77-split-1"),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13042, 85166, 2, "S77-split-2")
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                java.util.Map.of(11897, 24, 13041, 24, 13042, 24),
                java.util.Map.of(11897, 1064, 13041, 15629, 13042, 15629),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                Optional.empty());
        assertEquals("linked", advice.action());
        assertEquals(13042, advice.recommendIdKey());
        assertTrue(advice.messageText().contains("уже связана со слотом 13042"));
    }

    @Test
    void ambiguousVarBridgeDoesNotRecommendFirstSlot() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3796, 1, null, 902, 85166, "32-425/05-18", "А45-19974/2024",
                new BigDecimal("18000"),
                15629, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 24, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("18000"), null, null, null, null, null, 902);
        var slots = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13041, 85166, 1, "S77-split-1"),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(13042, 85166, 2, "S77-split-2")
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                java.util.Map.of(13041, 24, 13042, 24),
                java.util.Map.of(13041, 15629, 13042, 15629),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                Optional.empty());
        assertTrue(advice.messageText().contains("неоднозначен"));
        assertEquals("create_slot", advice.action());
        assertEquals(null, advice.recommendIdKey());
        assertTrue(advice.messageText().contains("Создать новый слот"));
    }

    @Test
    void createSlotWhenBridgePointsToSlotWithOtherAmount() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3792, 1, null, 902, 91637, "КС-51", "25456",
                new BigDecimal("183104935.38"),
                15390, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 21, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("183104935.38"), null, null, null, null, null, 902);
        var slot = new com.femsq.database.model.sudz.SudzInvDbtSlot(13044, 91637, 1, null);
        var timeline = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtTimelinePoint(
                        902,
                        LocalDate.parse("2026-03-31"),
                        new BigDecimal("3051748.93"),
                        BigDecimal.ZERO,
                        "dbtValue",
                        15390));
        var queueShares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(
                        3791, new BigDecimal("3051748.93"), null, 15390, 13044),
                new InvDbtDoubleAdvisor.OpenShare(
                        3792, new BigDecimal("183104935.38"), null, 15390, null)
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                List.of(slot),
                java.util.Map.of(13044, 21),
                java.util.Map.of(13044, 15390),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(13044, timeline),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                Optional.empty(),
                queueShares);
        assertEquals("create_slot", advice.action());
        assertEquals("high", advice.confidence());
        assertTrue(advice.messageText().contains("не предлагаем")
                || advice.messageText().contains("Создать новый слот"));
        assertTrue(advice.messageText().contains("13044"));
    }

    @Test
    void createSlotWhenNoSlotsOnInvFirstMultiDebts() {
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3791, 1, null, 902, 91637, "КС-51", "25456",
                new BigDecimal("3051748.93"),
                15390, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 21, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("3051748.93"), null, null, null, null, null, 902);
        var openShares = List.of(
                new InvDbtDoubleAdvisor.OpenShare(3791, new BigDecimal("3051748.93"), null, 15390),
                new InvDbtDoubleAdvisor.OpenShare(3792, new BigDecimal("183104935.38"), null, 15390)
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                List.of(),
                java.util.Map.of(),
                java.util.Map.of(),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                Optional.empty(),
                openShares);
        assertEquals("create_slot", advice.action());
        assertEquals("high", advice.confidence());
        assertTrue(advice.messageText().contains("нет слотов"));
        assertTrue(advice.messageText().contains("2 open-задолженности"));
        assertTrue(advice.messageText().contains("не Split"));
        assertTrue(advice.messageText().contains("Создать слот под сумму Excel"));
    }

    /**
     * КС-51 / 3616: слот 2031 с дырой в 2 квартала и попаданием 500.58
     * должен победить 2030 с «идеальным» R², но прогнозом мимо Excel.
     */
    @Test
    void amortPrefersProjectionHitOverPrettyR2WithoutHit() {
        // 2030: равномерный хвост −30417.39, последняя 19981.28 @ 2024-09-30 → прогноз мимо
        List<SudzInvDbtTimelinePoint> slot2030 = List.of(
                point("2023-12-31", 111233.45),
                point("2024-03-31", 80816.06),
                point("2024-06-30", 50398.67),
                point("2024-09-30", 19981.28)
        );
        // 2031: шаг −300.33; дыра Jun→Dec (−600.66 = 2 квартала); 800.91−300.33=500.58
        List<SudzInvDbtTimelinePoint> slot2031 = List.of(
                point("2024-03-31", 2903.22),
                point("2024-06-30", 2602.89),
                point("2024-09-30", 2302.56),
                point("2024-12-31", 2002.23),
                point("2025-03-31", 1701.90),
                point("2025-06-30", 1401.57),
                point("2025-12-31", 800.91)
        );
        var row = new com.femsq.database.model.sudz.SudzCnInvUplInvDbtDouble(
                3794, 1, null, 902, 5130, "КС-51", "3616 CR 0005",
                new BigDecimal("500.58"),
                10549, "multi", null, "open", null, null);
        var excel = new com.femsq.database.model.sudz.SudzSfDoubleExcelCandidate(
                1, null, 23, 761010, null, null, null, null, null, null, null, null, null,
                new BigDecimal("500.58"), null, null, null, null, null, 902);
        var slots = List.of(
                new com.femsq.database.model.sudz.SudzInvDbtSlot(2030, 5130, 1, "ciaName=1"),
                new com.femsq.database.model.sudz.SudzInvDbtSlot(2031, 5130, 2, "ciaName=2")
        );
        var advice = InvDbtDoubleAdvisor.advise(
                row,
                excel,
                slots,
                java.util.Map.of(2030, 23, 2031, 23),
                java.util.Map.of(2030, 10549, 2031, 10550),
                java.util.Optional.empty(),
                List.of(),
                java.util.Map.of(2030, slot2030, 2031, slot2031),
                LocalDate.parse("2026-03-31"),
                new BigDecimal("0.01"),
                Optional.empty(),
                Optional.empty());
        assertEquals("link", advice.action());
        assertEquals(2031, advice.recommendIdKey());
        assertEquals("high", advice.confidence());
        assertTrue(advice.messageText().contains("попадание Excel в тренд"));
        assertTrue(advice.messageText().contains("Связать со слотом 2031"));
    }

    private static SudzInvDbtTimelinePoint point(String date, double ttl) {
        return new SudzInvDbtTimelinePoint(
                null,
                LocalDate.parse(date),
                BigDecimal.valueOf(ttl),
                BigDecimal.ZERO,
                "dbtValue",
                6766);
    }
}
