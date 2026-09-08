package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import com.femsq.database.model.sudz.SudzSfDoubleHintItem;
import com.femsq.database.model.sudz.SudzSfDoubleHintSection;
import com.femsq.database.model.sudz.SudzSfDoubleHints;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Smoke-тесты эвристик советника КСДСФ.
 */
class SfDoubleAdvisorTest {

    @Test
    void sumSameCnOverridesCreateWhenInvNumDiffers() {
        // UAT C.10: Excel «Б/С» на СГМ14-234, DbtValue уже на том же cn под другим № СФ
        var row = new SudzCnInvUplSfDouble(
                169, 43903, null, null, null, 901, null, null,
                1312, "СГМ14-234", "Б/С", 1, "open", null, null);
        var sumItem = new SudzSfDoubleHintItem(
                "sumsNew", "dvKey", 43672, 91249, 1312, "СГМ14-234", "BUIRG",
                "dvKey=43672 · inv=91249");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection(
                        "no",
                        "В СФ с совпадающими номерами совпадающего контрагента (исполнитель) нет.",
                        0,
                        List.of()),
                sectionNa(),
                new SudzSfDoubleHintSection("yes", "sum new", 1, List.of(sumItem)));
        var domain = List.of(
                new SudzSfDoubleDomainMatch(91604, "Б/С", 91614, null, 94467, 308, "КС-51"));
        var advice = SfDoubleAdvisor.advise(row, null, hints, domain);
        assertEquals("link", advice.action());
        assertEquals("high", advice.confidence());
        assertEquals(91249, advice.recommendInvKey());
        assertEquals(1312, advice.recommendCnKey());
        assertTrue(advice.messageText().contains("sum_same_cn"));
        assertFalse(advice.messageText().contains("Создать СФ по Excel"));
    }

    @Test
    void cnHomonymRecommendsCreate() {
        var row = new SudzCnInvUplSfDouble(
                1, 100, null, null, null, 902, null, null,
                2206, "158", "1025", 2, "open", null, null);
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection(
                        "no",
                        "В СФ с совпадающими номерами совпадающего контрагента (исполнитель) нет.",
                        0,
                        List.of()),
                sectionNa(),
                sectionNa());
        var domain = List.of(
                new SudzSfDoubleDomainMatch(500, "1025", 1, null, 10, 999, "26/0215/20"));
        var advice = SfDoubleAdvisor.advise(row, null, hints, domain);
        assertTrue(advice.messageText().contains("[советник]"));
        assertEquals("create", advice.action());
        assertEquals("high", advice.confidence());
        assertTrue(advice.messageText().contains("Создать СФ по Excel"));
    }

    @Test
    void executorUniqueRecommendsLink() {
        var row = new SudzCnInvUplSfDouble(
                2, 101, null, null, null, 902, null, null,
                100, "711113884", "27185", 2, "open", null, null);
        var item = new SudzSfDoubleHintItem(
                "sf", "inKey", 55, 777, 100, "711113884", "BUIRG", "inv=777");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection(
                        "yes",
                        "В СФ с совпадающими номерами есть совпадающий контрагент (исполнитель).",
                        1,
                        List.of(item)),
                sectionNa(),
                sectionNa());
        var advice = SfDoubleAdvisor.advise(row, null, hints, List.of());
        assertEquals("link", advice.action());
        assertEquals("high", advice.confidence());
        assertEquals(777, advice.recommendInvKey());
        assertEquals(100, advice.recommendCnKey());
    }

    @Test
    void cnNumAliasWhenInvAlreadyOnCanonical() {
        var row = new SudzCnInvUplSfDouble(
                6, 105, null, null, null, 902, null, null,
                2600, "711113884", "27185", 2, "open", null, null);
        var item = new SudzSfDoubleHintItem(
                "sf", "inKey", 55, 54330, 2044, "711113884/ЯРЭС", "BUIRG", "inv=54330");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection("yes", "match", 1, List.of(item)),
                sectionNa(),
                sectionNa());
        var domain = List.of(
                new SudzSfDoubleDomainMatch(54330, "27185", 55, null, 57170, 2044, "711113884/ЯРЭС"));
        var advice = SfDoubleAdvisor.advise(row, null, hints, domain);
        assertEquals("alias_cn_num", advice.action());
        assertEquals(2044, advice.recommendCnKey());
        assertEquals(54330, advice.recommendInvKey());
        assertTrue(advice.messageText().contains("второй номер"));
        assertTrue(advice.messageText().contains("Договоры"));
    }

    @Test
    void cnNumVariantRecommendsLinkMediumWithoutSum() {
        var row = new SudzCnInvUplSfDouble(
                3, 102, null, null, null, 902, null, null,
                2600, "711113884", "27185", 2, "open", null, null);
        var item = new SudzSfDoubleHintItem(
                "sf", "inKey", 55, 54330, 2044, "711113884/ЯРЭС", "BUIRG", "inv=54330");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection(
                        "yes",
                        "есть совпадающий контрагент",
                        1,
                        List.of(item)),
                sectionNa(),
                sectionNa());
        var domain = List.of(
                new SudzSfDoubleDomainMatch(54330, "27185", 55, null, 1, 999, "711113884/ЯРЭС"));
        var advice = SfDoubleAdvisor.advise(row, null, hints, domain);
        assertEquals("link", advice.action());
        assertEquals("medium", advice.confidence());
        assertEquals(54330, advice.recommendInvKey());
        assertEquals(2044, advice.recommendCnKey());
    }

    @Test
    void cnNumVariantWithUniqueSumRecommendsLinkHigh() {
        var row = new SudzCnInvUplSfDouble(
                5, 104, null, null, null, 902, null, null,
                2600, "711113884", "27185", 2, "open", null, null);
        var sfItem = new SudzSfDoubleHintItem(
                "sf", "inKey", 55, 54330, 2044, "711113884/ЯРЭС", "BUIRG", "inv=54330");
        var sumItem = new SudzSfDoubleHintItem(
                "sumsOld", "cidKey", 51528, null, 2044, "711113884/ЯРЭС", "BUIRG", "cidKey=51528");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection("yes", "match", 1, List.of(sfItem)),
                new SudzSfDoubleHintSection("yes", "sum old", 1, List.of(sumItem)),
                sectionNa());
        var advice = SfDoubleAdvisor.advise(row, null, hints, List.of());
        assertEquals("link", advice.action());
        assertEquals("high", advice.confidence());
    }

    @Test
    void cnNumbersAreVariants_detectsSuffix() {
        assertTrue(SfDoubleAdvisor.cnNumbersAreVariants("711113884", "711113884/ЯРЭС"));
        assertTrue(SfDoubleAdvisor.cnNumbersAreVariants("711113884", "711113884/ярэс"));
        assertTrue(SfDoubleAdvisor.cnNumbersAreVariants("711114584", "711114584/АРЭС"));
        assertTrue(SfDoubleAdvisor.cnNumbersAreVariants("711113884 ", " 711113884 / ЯРЭС "));
        assertFalse(SfDoubleAdvisor.cnNumbersAreVariants("8206Д-25/ГГЭ-45876/1", "26/0215/20"));
    }

    @Test
    void executorUniqueOnUnrelatedCnRecommendsCreate() {
        var row = new SudzCnInvUplSfDouble(
                4, 103, null, null, null, 902, null, null,
                2577, "8206Д-25/ГГЭ-45876/1", "1025", 2, "open", null, null);
        var item = new SudzSfDoubleHintItem(
                "sf", "inKey", 1, 500, 999, "26/0215/20", "BUIRG", "inv=500");
        var hints = new SudzSfDoubleHints(
                new SudzSfDoubleHintSection("yes", "match", 1, List.of(item)),
                sectionNa(),
                sectionNa());
        var advice = SfDoubleAdvisor.advise(row, null, hints, List.of());
        assertEquals("create", advice.action());
        assertEquals("high", advice.confidence());
    }

    private static SudzSfDoubleHintSection sectionNa() {
        return new SudzSfDoubleHintSection("na", "нет данных", 0, List.of());
    }
}
