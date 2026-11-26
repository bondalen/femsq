package com.femsq.database.util;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class AggAxisTest {

    @Test
    void ok_whenExactAfterRound() {
        AggAxisResult r = AggAxis.reconcileMln(
                bd("100.00000000"),
                bd("50.00000000"),
                bd("30.00000000"),
                bd("20.00000000"));
        assertEquals(AggAxisKind.OK, r.kind());
        assertEquals(AggAxisResult.CODE_OK, r.logCode());
        assertTrue(r.writable());
    }

    @Test
    void quantumFix_site3555Pattern() {
        // Ttl на 1e-8 больше суммы частей
        AggAxisResult r = AggAxis.reconcileMln(
                bd("1634.23604378"),
                bd("1470.8124394"),
                bd("114.39652306"),
                bd("49.02708131"));
        assertEquals(AggAxisKind.QUANTUM_FIX, r.kind());
        assertEquals(bd("1634.23604378"), r.ttl());
        assertEquals(bd("49.02708132"), r.oth());
        assertEquals(0, r.ttl().subtract(r.wrk().add(r.equ()).add(r.oth())).compareTo(BigDecimal.ZERO));
    }

    @Test
    void block_whenDeltaAboveFloor() {
        // parts=90, δ=10 > ε_block=max(1, 1%·100)=1
        AggAxisResult r = AggAxis.reconcileMln(
                bd("100.00000000"),
                bd("40.00000000"),
                bd("30.00000000"),
                bd("20.00000000"));
        assertEquals(AggAxisKind.BLOCK, r.kind());
        assertFalse(r.writable());
    }

    @Test
    void authorFix_smallMismatch() {
        // δ = 0.0001 млн (= 100 ₽) — больше ε_q, меньше ε_block=1
        AggAxisResult r = AggAxis.reconcileMln(
                bd("100.00010000"),
                bd("50"),
                bd("30"),
                bd("20"));
        assertEquals(AggAxisKind.AUTHOR_FIX, r.kind());
        assertEquals(bd("100.00000000"), r.ttl());
        assertEquals(AggAxisResult.CODE_AUTHOR, r.logCode());
    }

    @Test
    void struct_ttlWithoutParts() {
        AggAxisResult r = AggAxis.reconcileMln(bd("10"), null, null, null);
        assertEquals(AggAxisKind.STRUCT, r.kind());
        assertEquals(bd("10.00000000"), r.ttl());
        assertTrue(r.writable());
    }

    @Test
    void struct_partsWithoutTtl() {
        AggAxisResult r = AggAxis.reconcileMln(null, bd("1"), bd("2"), bd("3"));
        assertEquals(AggAxisKind.STRUCT, r.kind());
        assertTrue(r.writable());
    }

    @Test
    void roundMln_fromDoubleNoise() {
        BigDecimal raw = BigDecimal.valueOf(1.234567891234);
        assertEquals(bd("1.23456789"), FemsqMoney.roundMln(raw));
    }

    private static BigDecimal bd(String s) {
        return new BigDecimal(s);
    }
}
