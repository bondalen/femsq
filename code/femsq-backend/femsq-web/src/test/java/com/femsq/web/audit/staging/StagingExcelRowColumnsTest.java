package com.femsq.web.audit.staging;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Set;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты выбора синтетической колонки Excel-строки (0051 / §9.3.6.2).
 */
class StagingExcelRowColumnsTest {

    @Test
    void find_prefersKnownNamesInDbColumns() {
        assertEquals("rainRow", StagingExcelRowColumns.find(Set.of("rain_exec_key", "rainRow", "rainRaNum")));
        assertEquals("ralprtRow", StagingExcelRowColumns.find(Set.of("ralprt_exec_key", "ralprtRow", "ralprtNum")));
        assertEquals("ralprsRow", StagingExcelRowColumns.find(Set.of("ralprs_exec_key", "ralprsRow")));
    }

    @Test
    void find_caseInsensitive() {
        assertEquals("RainRow", StagingExcelRowColumns.find(Set.of("RainRow", "rainRaNum")));
    }

    @Test
    void find_returnsNullWhenAbsent() {
        assertNull(StagingExcelRowColumns.find(Set.of("ralprtNum", "ralprt_exec_key")));
        assertNull(StagingExcelRowColumns.find(Set.of()));
        assertNull(StagingExcelRowColumns.find(null));
    }

    @Test
    void isSynthetic_matchesConfiguredColumn() {
        assertTrue(StagingExcelRowColumns.isSynthetic("ralprtRow", "ralprtRow"));
        assertTrue(StagingExcelRowColumns.isSynthetic("rainRow", "rainRow"));
        assertFalse(StagingExcelRowColumns.isSynthetic("ralprtNum", "ralprtRow"));
        assertFalse(StagingExcelRowColumns.isSynthetic("ralprtRow", null));
    }
}
