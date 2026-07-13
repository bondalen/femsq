package com.femsq.web.audit.staging;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class StagingRowSkipReasonFormatterTest {

    @Test
    void formatMissingRequiredFields_showsFirstThreeAndRemainder() {
        String reason = StagingRowSkipReasonFormatter.formatMissingRequiredFields(
                List.of("ralprtNum", "ralprtDate", "ralprtCst", "ralprtOg"),
                Map.of(
                        "ralprtNum", "№ отчёта",
                        "ralprtDate", "Дата",
                        "ralprtCst", "Заказчик",
                        "ralprtOg", "ОГ"
                )
        );
        assertEquals(
                "пропущено — пусто обязательное поле: ralprtNum («№ отчёта»), "
                        + "ralprtDate («Дата»), ralprtCst («Заказчик») и ещё 1",
                reason
        );
    }

    @Test
    void formatMissingRequiredFields_singleFieldWithoutHeader() {
        String reason = StagingRowSkipReasonFormatter.formatMissingRequiredFields(
                List.of("rainSign"),
                Map.of()
        );
        assertEquals("пропущено — пусто обязательное поле: rainSign", reason);
    }
}
