package com.femsq.database.util;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class StructureNameNormalizerTest {

    @Test
    void normalize_stripsNumberingAndQuotes() {
        assertEquals(
                "обустройство чаяндинского м/р и мг \"сила сибири\"",
                StructureNameNormalizer.normalize(
                        "1.1.1. Обустройство Чаяндинского м/р и МГ «Сила Сибири»"));
    }

    @Test
    void stripSectionNumber_keepsCase() {
        assertEquals(
                "Приоритетные проекты",
                StructureNameNormalizer.stripSectionNumber("1. Приоритетные проекты "));
    }

    @Test
    void normalize_unifiesMrAndIslandSpacing() {
        assertEquals(
                "добыча и бурение на м/р",
                StructureNameNormalizer.normalize("2.1. Добыча и бурение на м.р."));
        assertEquals(
                StructureNameNormalizer.normalize("о.Сахалин"),
                StructureNameNormalizer.normalize("о. Сахалин"));
    }
}
