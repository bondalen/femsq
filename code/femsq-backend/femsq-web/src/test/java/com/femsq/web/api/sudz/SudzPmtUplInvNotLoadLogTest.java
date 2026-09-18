package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvItem;
import com.femsq.database.model.sudz.SudzPmtUplInvNotContract;
import com.femsq.database.model.sudz.SudzPmtUplInvNotResult;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Лог шага 7 платежей.
 */
class SudzPmtUplInvNotLoadLogTest {

    @Test
    void appendEmpty() {
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        SudzPmtUplInvNotLoadLog.append(log, new SudzPmtUplInvNotResult(0, List.of()), null);
        assertTrue(log.toHtml().contains("отсутствуют договора"));
    }

    @Test
    void formatContractShowsBuirgAndInv() {
        SudzPmtUplInvNotContract contract = new SudzPmtUplInvNotContract(
                2278,
                "0554Д-25/ГГЭ-34481/1",
                1015195,
                "ООО Тест",
                1,
                List.of(new SudzDbtUplCnCtptExistInvItem("19276", null))
        );
        String html = SudzPmtUplInvNotLoadLog.formatContract(1, contract);
        assertTrue(html.contains("1015195"));
        assertTrue(html.contains("19276"));
        assertTrue(html.contains("CnId"));
    }
}
