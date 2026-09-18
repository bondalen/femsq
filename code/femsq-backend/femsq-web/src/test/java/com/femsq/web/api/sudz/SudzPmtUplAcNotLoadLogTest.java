package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplAcNotLoad;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 9 платежей.
 */
class SudzPmtUplAcNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplAcNotLoadLog.append(log, List.of(), null);
        assertTrue(log.toHtml().contains("отсутствуют счета-фактуры"));
    }

    @Test
    void formatRowShowsAccount() {
        SudzPmtUplAcNotLoad row = new SudzPmtUplAcNotLoad(
                96053, 100, 606012, 5, 1015195, "ООО", "ДГ-1", 2278, "19276");
        String html = SudzPmtUplAcNotLoadLog.formatRow(1, row);
        assertTrue(html.contains("606012"));
        assertTrue(html.contains("19276"));
        assertTrue(html.contains("ciKey"));
    }
}
