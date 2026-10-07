package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzCnInvUplSfDouble;
import com.femsq.database.model.sudz.SudzPmDocForest;
import com.femsq.database.model.sudz.SudzPmDocLink;
import com.femsq.database.model.sudz.SudzSfDoubleDomainMatch;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Строка советника по истории платёжного документа не выбирает действие.
 */
class PmDocHistoryNoteTest {

    @Test
    void differentInvoiceNumberIsTextOnly() {
        String text = PmDocHistoryNote.text(
                pmtRow("94", 308),
                null,
                List.of(),
                forest(59, link(1, 35, "ГИ241227-0009-36", 78052, 308, "767501"))
        );
        assertTrue(text.contains("был на СФ"));
        assertTrue(text.contains("Автовыбор не делается"));
    }

    @Test
    void severalInvoicesDoNotPick() {
        String text = PmDocHistoryNote.text(
                pmtRow("93", 308),
                null,
                List.of(),
                forest(59, link(1, 16, "11-03/05-27", 11, 308, "767501"),
                        link(2, 35, "ГИ241231-0510-36", 22, 308, "767501"))
        );
        assertTrue(text.contains("расходятся"));
    }

    @Test
    void matchingNumberConfirmsWithoutChoosing() {
        String text = PmDocHistoryNote.text(
                pmtRow("94", 308),
                null,
                List.of(new SudzSfDoubleDomainMatch(23785, "94", 1, null, 1, 308, "КС-51", null, null)),
                forest(59, link(1, 45, "94", 23785, 308, "767501"))
        );
        assertTrue(text.contains("подтверждает СФ"));
        assertTrue(text.contains("inv=23785"));
    }

    private static SudzCnInvUplSfDouble pmtRow(String inv, int cn) {
        return new SudzCnInvUplSfDouble(
                1275, null, 148010, null, null, 59, null, null,
                cn, "КС-51", inv, 1, "open", null, null);
    }

    private static SudzPmDocForest forest(int current, SudzPmDocLink... links) {
        return new SudzPmDocForest(1, links.length, current, List.of(links));
    }

    private static SudzPmDocLink link(
            int docKey, int upl, String invNum, int invKey, int cn, String account
    ) {
        return new SudzPmDocLink(
                docKey, "5400217611", null, null,
                docKey * 10, upl, "export-" + upl, null,
                BigDecimal.ONE, null, null,
                invKey, invNum, cn, "КС-51", "КС-51", "1009345", account,
                null, null, null
        );
    }
}
