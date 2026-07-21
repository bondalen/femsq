package com.femsq.web.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

/**
 * Формат сумм в логе ревизии (0056).
 */
class AuditMoneyFormatTest {

    @Test
    void formatsWithSpacesAndComma() {
        assertEquals("5 558 976 847,24",
                AuditMoneyFormat.format(new BigDecimal("5558976847.24")));
        assertEquals("5 558 976 847,24",
                AuditMoneyFormat.format(new BigDecimal("5558976847.2400")));
        assertEquals("0,00", AuditMoneyFormat.format(BigDecimal.ZERO));
        assertEquals("0,00", AuditMoneyFormat.format(null));
        assertEquals("100,50", AuditMoneyFormat.format(new BigDecimal("100.5")));
    }
}
