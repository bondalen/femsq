package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplContinuityRow;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadSnapshot;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code dbtValueLoad} (C2).
 */
public final class SudzDbtUplDbtValueLoadLog {

    private static final int MAX_CONTINUITY_LINES = 40;

    private SudzDbtUplDbtValueLoadLog() {
    }

    /**
     * Пишет снимок и итог apply.
     *
     * @param progress лог
     * @param snapshot снимок до/после apply
     * @param applyResult итог apply или null
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            SudzDbtUplDbtValueLoadSnapshot snapshot,
            SudzDbtUplDbtValueLoadApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(snapshot, "snapshot");
        Integer base = snapshot.baseUpl();
        if (base == null) {
            progress.line("<font color=\"Salmon\">год для upl не найден</font>"
                    + " — diff base→curr и очередь P1 пропущены");
        } else {
            progress.line("Base upl года: <font color=\"DarkCyan\">" + base + "</font>");
        }
        progress.line("Skip (Value на curr): <font color=\"DarkCyan\">" + snapshot.skippedValues() + "</font>"
                + "; tail: <font color=\"DarkCyan\">" + snapshot.tailReady() + "</font>"
                + " (без однозн. Excel→slot: " + snapshot.tailAmbiguous() + ")"
                + "; исчезло Dbt: <font color=\"DarkCyan\">" + snapshot.disappeared() + "</font>"
                + "; P1 в очереди: <font color=\"DarkCyan\">" + snapshot.p1Queued()
                + "</font> (open: " + snapshot.p1Open() + ")");
        appendContinuityBlock(progress, snapshot.continuity());
        if (snapshot.varInvMismatch() > 0) {
            progress.line("<font color=\"Salmon\"><b>Ошибка:</b> invDbtVar.invNum ≠ СФ выгрузки/свода (Tbl) "
                    + "у <b>" + snapshot.varInvMismatch() + "</b> DbtValue на curr — см. server log "
                    + "(dbtValueLoad varInvMismatch)</font>");
        }
        if (applyResult == null) {
            return;
        }
        progress.line("Apply: DbtValue tail=<b><font color=\"DarkGreen\">" + applyResult.insertedValues()
                + "</font></b>; P1 rebuild=<b><font color=\"DarkGreen\">" + applyResult.p1Queued()
                + "</font></b>; Excel без однозн. слота пропущено=<b><font color=\"Salmon\">"
                + applyResult.skippedTailAmbiguous() + "</font></b>");
    }

    /**
     * Блок «Непрерывность слотов» (S77.9 M3).
     *
     * @param progress лог
     * @param rows кандидаты 1 Excel + N слотов
     */
    static void appendContinuityBlock(SudzDbtUplProgressLog progress, List<SudzDbtUplContinuityRow> rows) {
        if (rows == null || rows.isEmpty()) {
            progress.line("Непрерывность слотов (1 Excel, N слотов): <font color=\"Goldenrod\">нет</font>.");
            return;
        }
        progress.line("Непрерывность слотов (1 Excel, N слотов): <font color=\"CadetBlue\"><b>"
                + rows.size() + "</b></font>");
        int limit = Math.min(rows.size(), MAX_CONTINUITY_LINES);
        for (int i = 0; i < limit; i++) {
            progress.line(formatContinuity(i + 1, rows.get(i)));
        }
        if (rows.size() > MAX_CONTINUITY_LINES) {
            progress.line("<font color=\"silver\">… и ещё "
                    + (rows.size() - MAX_CONTINUITY_LINES) + "</font>");
        }
    }

    private static String formatContinuity(int index, SudzDbtUplContinuityRow row) {
        String decisionRu = switch (row.decision() == null ? "" : row.decision()) {
            case "pick_base" -> "→ слот " + row.chosenSlotKey() + " (Value@base)";
            case "pick_last" -> "→ слот " + row.chosenSlotKey() + " (lastTtl)";
            case "ambiguous" -> "→ <font color=\"Salmon\">неоднозначно</font> (не silent)";
            case "single" -> "→ один слот";
            default -> "→ " + row.decision();
        };
        return index + ". СФ <b>" + nullToDash(row.cnInv()) + "</b>"
                + " / договор " + nullToDash(row.cnName())
                + " / iKey=" + row.iKey()
                + " / сумма " + row.debt()
                + " / слотов=" + row.slotCount()
                + " " + decisionRu
                + ". Кандидаты: " + (row.candidates() == null || row.candidates().isBlank()
                ? "—"
                : row.candidates())
                + ".";
    }

    private static String nullToDash(String value) {
        return value == null || value.isBlank() ? "—" : value;
    }
}
