package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadCalmRow;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Лог dry-run invDbtLoad: Calm Create в HTML. */
class SudzDbtUplInvDbtLoadLogTest {

    @Test
    void dryRunListsCalmCreateRows() {
        var progress = new SudzDbtUplProgressLog();
        var row = new SudzDbtUplInvDbtLoadCalmRow(
                49482,
                "8206Д-25/ГГЭ-45876/1",
                "1025",
                new BigDecimal("6332971.16"),
                92012,
                15641,
                "calm_create");
        var result = new SudzDbtUplInvDbtLoadApplyResult(
                0, 0, 0, 0, List.of(row), List.of(), List.of());
        SudzDbtUplInvDbtLoadLog.append(progress, result, false);
        String html = progress.toHtml();
        assertTrue(html.contains("Calm Create"), html);
        assertTrue(html.contains("49482"), html);
        assertTrue(html.contains("92012"), html);
        assertTrue(html.contains("dry — не записано") || html.contains("dry-run"), html);
    }
}
