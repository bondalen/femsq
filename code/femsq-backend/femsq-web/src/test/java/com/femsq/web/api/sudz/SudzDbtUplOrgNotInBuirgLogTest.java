package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplOrgNotInBuirg;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * HTML шага orgNotInBuirg (цвета Access).
 */
class SudzDbtUplOrgNotInBuirgLogTest {

    @Test
    void emptySourceUsesOliveMessage() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzDbtUplOrgNotInBuirgLog.append(log, List.of());
        String html = log.toHtml();
        assertTrue(html.contains("новые организации отсутствуют"));
        assertTrue(html.contains("Olive"));
        assertFalse(html.contains("Новая:"));
    }

    @Test
    void rowWithExistingOgNmUsesSalmonAndMaroon() {
        SudzDbtUplOrgNotInBuirg row = new SudzDbtUplOrgNotInBuirg(
                1039126,
                "ФИЛИАЛ ПАО \"РОССЕТИ ЦЕНТР\"",
                "6901067107",
                "Россети Центр, ПАО"
        );
        String html = SudzDbtUplOrgNotInBuirgLog.formatRow(1, row);
        assertTrue(html.contains("DarkCyan"));
        assertTrue(html.contains("1039126"));
        assertTrue(html.contains("6901067107"));
        assertTrue(html.contains("Уже имеется"));
        assertTrue(html.contains("Maroon"));
        assertTrue(html.contains("&quot;РОССЕТИ ЦЕНТР&quot;"));
    }

    @Test
    void rowWithoutOgNmClosesSilverFont() {
        SudzDbtUplOrgNotInBuirg row = new SudzDbtUplOrgNotInBuirg(
                1039577,
                "ООО БУРГЕОКОМ",
                "3403017860",
                null
        );
        String html = SudzDbtUplOrgNotInBuirgLog.formatRow(2, row);
        assertTrue(html.contains("Новая: <font color=\"DarkSlateBlue\">2</font>"));
        assertTrue(html.contains("ООО БУРГЕОКОМ"));
        assertFalse(html.contains("Уже имеется"));
        assertEquals("</font>.", html.substring(html.length() - 8));
    }
}
