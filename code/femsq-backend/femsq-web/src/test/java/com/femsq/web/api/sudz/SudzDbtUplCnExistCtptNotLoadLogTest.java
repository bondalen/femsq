package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplCnExistCtptNotLoad;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * HTML шага CnExistCtptNotLoad (цвета Access).
 */
class SudzDbtUplCnExistCtptNotLoadLogTest {

    @Test
    void emptySourceUsesGoldenrodMessage() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzDbtUplCnExistCtptNotLoadLog.append(log, List.of());
        String html = log.toHtml();
        assertTrue(html.contains("исполнитель по которым не соответствует"));
        assertTrue(html.contains("Goldenrod"));
        assertFalse(html.contains("Новый:"));
    }

    @Test
    void rowWithDate() {
        SudzDbtUplCnExistCtptNotLoad row = new SudzDbtUplCnExistCtptNotLoad(
                1060645,
                "Россети Волга, ПАО",
                "6450925977",
                "2540-000097",
                LocalDate.of(2025, 8, 15),
                1
        );
        String html = SudzDbtUplCnExistCtptNotLoadLog.formatRow(1, row);
        assertTrue(html.contains("Новый: <font color=\"DarkSlateBlue\">1</font>"));
        assertTrue(html.contains("1060645"));
        assertTrue(html.contains("2540-000097"));
        assertTrue(html.contains("15.08.2025"));
        assertFalse(html.contains("OrgId"));
        assertFalse(html.contains("дата отсутствует"));
    }

    @Test
    void rowWithMissingDate() {
        SudzDbtUplCnExistCtptNotLoad row = new SudzDbtUplCnExistCtptNotLoad(
                1039577,
                "БУРГЕОКОМ, ООО",
                "3403017860",
                "Б/Н",
                LocalDate.of(1900, 1, 1),
                6
        );
        String html = SudzDbtUplCnExistCtptNotLoadLog.formatRow(2, row);
        assertTrue(html.contains("дата отсутствует"));
        assertTrue(html.contains("Б/Н"));
    }
}
