package com.femsq.web.audit.staging;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Set;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты классификации строк type=5 (пустое vs аренда vs whitelist) и границы диапазона.
 */
class Type5SignFilterClassifierTest {

    private static final Set<String> WHITELIST = Set.of("оа", "оа изм", "оа прочие");
    private static final Pattern RA_NUM = Type5SignFilterClassifier.compileRaNumPattern("\\d{7}");

    @Test
    void emptySignAndEmptyRaNum_isEmpty_notUnknownSign() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify(null, null, WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.EMPTY, d.kind());
        assertNull(d.label());

        d = Type5SignFilterClassifier.classify("  ", "  ", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.EMPTY, d.kind());
    }

    @Test
    void whitelistSigns_areAccepted() {
        assertEquals(
                Type5SignFilterClassifier.Kind.ACCEPTED,
                Type5SignFilterClassifier.classify("ОА", "1234567", WHITELIST).kind()
        );
        assertEquals(
                Type5SignFilterClassifier.Kind.ACCEPTED,
                Type5SignFilterClassifier.classify("ОА изм", "x", WHITELIST).kind()
        );
        assertEquals(
                Type5SignFilterClassifier.Kind.ACCEPTED,
                Type5SignFilterClassifier.classify("оа прочие", "y", WHITELIST).kind()
        );
    }

    @Test
    void arendaSign_isFilteredArenda_evenWithDirtyNumber() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify("ОА Аренда", "0046/31025", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.FILTERED_ARENDA, d.kind());
        assertEquals(Type5SignFilterClassifier.ARENADA_SIGN_LABEL, d.label());
    }

    @Test
    void arendaSign_withEmptyRaNum_stillFilteredArenda_notEmpty() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify("ОА Аренда", "", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.FILTERED_ARENDA, d.kind());
    }

    @Test
    void emptySign_butNonEmptyRaNum_isUnknownSignOther() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify(null, "2132.0", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.FILTERED_OTHER, d.kind());
        assertEquals(Type5SignFilterClassifier.UNKNOWN_SIGN_LABEL, d.label());
    }

    @Test
    void otherNonWhitelistSign_keepsRawLabel() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify("Служебный", "ABC", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.FILTERED_OTHER, d.kind());
        assertEquals("Служебный", d.label());
    }

    @Test
    void otherWithoutMarker_whenNoSevenDigits() {
        Type5SignFilterClassifier.Decision d =
                Type5SignFilterClassifier.classify(null, "2132.0", WHITELIST);
        assertTrue(Type5SignFilterClassifier.isOtherWithoutRaNumMarker(d, "2132.0", RA_NUM));
        assertFalse(Type5SignFilterClassifier.isOtherWithoutRaNumMarker(
                Type5SignFilterClassifier.classify("ОА", "x", WHITELIST), "x", RA_NUM));
        Type5SignFilterClassifier.Decision withDigits =
                Type5SignFilterClassifier.classify("Служебный", "СЗ26-2001507Е1", WHITELIST);
        assertEquals(Type5SignFilterClassifier.Kind.FILTERED_OTHER, withDigits.kind());
        assertFalse(Type5SignFilterClassifier.isOtherWithoutRaNumMarker(
                withDigits, "СЗ26-2001507Е1", RA_NUM));
    }

    @Test
    void significantForRange_whitelistOrArendaOrSevenDigits() {
        assertTrue(Type5SignFilterClassifier.isSignificantForDataRange(
                "ОА", "СЗ-1", WHITELIST, RA_NUM));
        assertTrue(Type5SignFilterClassifier.isSignificantForDataRange(
                "ОА Аренда", "0046/31025", WHITELIST, RA_NUM));
        assertTrue(Type5SignFilterClassifier.isSignificantForDataRange(
                null, "НПТУxx3001052-1", WHITELIST, RA_NUM));
        assertTrue(Type5SignFilterClassifier.isSignificantForDataRange(
                "", "СЗ26-2001507Е1", WHITELIST, RA_NUM));
        assertFalse(Type5SignFilterClassifier.isSignificantForDataRange(
                null, "2132.0", WHITELIST, RA_NUM));
        assertFalse(Type5SignFilterClassifier.isSignificantForDataRange(
                null, null, WHITELIST, RA_NUM));
        assertFalse(Type5SignFilterClassifier.isSignificantForDataRange(
                "Служебный", "ABC", WHITELIST, RA_NUM));
    }

    @Test
    void significantForRange_collapsesWhitespaceInRaNum() {
        assertTrue(Type5SignFilterClassifier.isSignificantForDataRange(
                null, "300\n1052", WHITELIST, RA_NUM));
    }

    @Test
    void compileRaNumPattern_invalidFallsBackToDefault() {
        Pattern p = Type5SignFilterClassifier.compileRaNumPattern("[invalid");
        assertTrue(p.matcher("1234567").find());
    }

    @Test
    void normalizeRaNum_removesAllWhitespace() {
        assertEquals("ABC1234567", Type5SignFilterClassifier.normalizeRaNum("AB C\n1234567"));
        assertEquals("", Type5SignFilterClassifier.normalizeRaNum("  \n\t  "));
    }
}
