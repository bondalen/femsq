package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplCnNotLoad;
import com.femsq.database.model.sudz.SudzDbtUplCnNotLoadInserted;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * HTML шага CnNotLoad (цвета Access).
 */
class SudzDbtUplCnNotLoadLogTest {

    @Test
    void emptySourceUsesGoldenrodMessage() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzDbtUplCnNotLoadLog.append(log, List.of(), null);
        String html = log.toHtml();
        assertTrue(html.contains("новые договора отсутствуют"));
        assertTrue(html.contains("Goldenrod"));
        assertFalse(html.contains("Новый:"));
    }

    @Test
    void rowWithDateAndNoRepeats() {
        SudzDbtUplCnNotLoad row = new SudzDbtUplCnNotLoad(
                1072462,
                52,
                "Россети Центр, ПАО",
                "6901067107",
                "TEST-CN-1",
                LocalDate.of(2020, 5, 15),
                0,
                1
        );
        String html = SudzDbtUplCnNotLoadLog.formatRow(1, row, null);
        assertTrue(html.contains("Новый: <font color=\"DarkSlateBlue\">1</font>"));
        assertTrue(html.contains("1072462"));
        assertTrue(html.contains("OrgId: <font color=\"DarkViolet\">52</font>"));
        assertTrue(html.contains("15.05.2020"));
        assertTrue(html.contains("Повторы № среди новых"));
        assertTrue(html.contains("DarkGreen"));
        assertFalse(html.contains("дата отсутствует"));
        assertFalse(html.contains("Добавлено"));
    }

    @Test
    void rowWithInsertShowsCnIds() {
        SudzDbtUplCnNotLoad row = new SudzDbtUplCnNotLoad(
                1, 2, "Орг", "123", "CN", LocalDate.of(2021, 1, 2), 0, 1
        );
        SudzDbtUplCnNotLoadInserted inserted = new SudzDbtUplCnNotLoadInserted(10, 20, 30, 40, 50);
        String html = SudzDbtUplCnNotLoadLog.formatRow(1, row, inserted);
        assertTrue(html.contains("Добавлено"));
        assertTrue(html.contains("CnId: <font color=\"CadetBlue\">10</font>"));
        assertTrue(html.contains("CnS_OrgId: <font color=\"Teal\">50</font>"));
    }

    @Test
    void rowWithNullDateAndRepeats() {
        SudzDbtUplCnNotLoad row = new SudzDbtUplCnNotLoad(
                1,
                2,
                "Орг",
                "123",
                "DUP",
                LocalDate.of(1900, 1, 1),
                0,
                3
        );
        String html = SudzDbtUplCnNotLoadLog.formatRow(2, row, null);
        assertTrue(html.contains("дата отсутствует"));
        assertTrue(html.contains("Salmon"));
        assertTrue(html.contains(">3</font>"));
    }
}
