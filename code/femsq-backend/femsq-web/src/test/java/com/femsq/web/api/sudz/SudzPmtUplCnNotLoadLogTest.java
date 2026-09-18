package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplCnNotLoad;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 3 платежей.
 */
class SudzPmtUplCnNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplCnNotLoadLog.append(log, List.of(), null);
        String html = log.toHtml();
        assertTrue(html.contains("новые договоры"));
    }

    @Test
    void formatRowWithCountCn() {
        SudzPmtUplCnNotLoad row = new SudzPmtUplCnNotLoad(15, 100, "ООО Тест", "ДГ-1", 2);
        String html = SudzPmtUplCnNotLoadLog.formatRow(1, row, null);
        assertTrue(html.contains("countCn="));
        assertTrue(html.contains("похожий №"));
    }
}
