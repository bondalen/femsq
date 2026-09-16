package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplContinuityRow;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadSnapshot;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Dry-лог непрерывности {@code dbtValueLoad} (S77.9 M3).
 */
class SudzDbtUplDbtValueLoadLogTest {

    @Test
    void appendWritesContinuityBlock() {
        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        SudzDbtUplDbtValueLoadSnapshot snapshot = new SudzDbtUplDbtValueLoadSnapshot(
                901,
                10,
                1,
                0,
                0,
                0,
                0,
                0,
                List.of(new SudzDbtUplContinuityRow(
                        1,
                        6760,
                        "28469",
                        "КС-51",
                        new BigDecimal("2733213421.80"),
                        2,
                        3398,
                        "pick_base",
                        "3398(r0),3399(r3)")));
        SudzDbtUplDbtValueLoadLog.append(progress, snapshot, null);
        String html = progress.toHtml();
        assertTrue(html.contains("Непрерывность слотов"), html);
        assertTrue(html.contains("28469"), html);
        assertTrue(html.contains("Value@base"), html);
        assertTrue(html.contains("3398"), html);
    }

    @Test
    void appendWritesEmptyContinuity() {
        SudzDbtUplProgressLog progress = new SudzDbtUplProgressLog();
        SudzDbtUplDbtValueLoadSnapshot snapshot = new SudzDbtUplDbtValueLoadSnapshot(
                901, 0, 0, 0, 0, 0, 0, 0, List.of());
        SudzDbtUplDbtValueLoadLog.append(progress, snapshot, null);
        assertTrue(progress.toHtml().contains("Непрерывность слотов"), progress.toHtml());
        assertTrue(progress.toHtml().contains("нет"), progress.toHtml());
    }
}
