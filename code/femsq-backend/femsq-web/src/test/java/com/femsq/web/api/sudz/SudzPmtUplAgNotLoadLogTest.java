package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplAgNotLoad;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 5 платежей.
 */
class SudzPmtUplAgNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplAgNotLoadLog.append(log, List.of(), null);
        assertTrue(log.toHtml().contains("договоры без агента"));
    }

    @Test
    void formatRowWithoutOrg() {
        SudzPmtUplAgNotLoad row = new SudzPmtUplAgNotLoad(10, null, "ДГ-1", 15, "ООО Агент", null);
        String html = SudzPmtUplAgNotLoadLog.formatRow(1, row, null);
        assertTrue(html.contains("нет org_id"));
        assertTrue(html.contains("cn_key"));
    }
}
