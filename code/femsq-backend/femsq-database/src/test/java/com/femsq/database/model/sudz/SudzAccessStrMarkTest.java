package com.femsq.database.model.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;

/**
 * Формат Access {@code strMark}.
 */
class SudzAccessStrMarkTest {

    @Test
    void augustSingleDigitMonth() {
        assertEquals(8142105, SudzAccessStrMark.from(LocalDateTime.of(2026, 8, 14, 21, 5)));
    }

    @Test
    void decemberTwoDigitMonth() {
        assertEquals(12140903, SudzAccessStrMark.from(LocalDateTime.of(2026, 12, 14, 9, 3)));
    }
}
