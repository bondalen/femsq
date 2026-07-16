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

    @Test
    void formatEmptyRowsBatch_singleRow() {
        assertEquals(
                "Excel-строка 2: пропущено как пустая (нет данных по колонкам маппинга)",
                StagingRowSkipReasonFormatter.formatEmptyRowsBatch(2, 2, 1)
        );
    }

    @Test
    void formatEmptyRowsBatch_range() {
        assertEquals(
                "Excel-строки 427–3556 (3123 шт.): пропущено как пустые (нет данных по колонкам маппинга)",
                StagingRowSkipReasonFormatter.formatEmptyRowsBatch(427, 3556, 3123)
        );
    }

    @Test
    void formatBeyondDataRange() {
        assertEquals(
                "За пределами диапазона $P$2:$P$426 (ниже строки 426) не обрабатывалось 3129 строк листа (хвост Excel / форматирование)",
                StagingRowSkipReasonFormatter.formatBeyondDataRange("$P$2:$P$426", 426, 3129)
        );
    }

    @Test
    void formatType5OtherWithoutMarker() {
        assertEquals(
                "прочий номер/признак без маркера ОА (\\d{7}): Признак = «—», № ОА = «2132.0»",
                StagingRowSkipReasonFormatter.formatType5OtherWithoutMarker(null, "2132.0")
        );
    }

    @Test
    void formatType5OtherOverflow() {
        assertEquals(
                "и ещё 3 прочих строк без маркера № ОА (см. топ выше / хвост)",
                StagingRowSkipReasonFormatter.formatType5OtherOverflow(3)
        );
    }
}
