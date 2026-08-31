package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplDbtValueLoadSnapshot;
import java.util.Objects;

/**
 * HTML-лог шага {@code dbtValueLoad} (C2).
 */
public final class SudzDbtUplDbtValueLoadLog {

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
                + " (ambiguous: " + snapshot.tailAmbiguous() + ")"
                + "; исчезло Dbt: <font color=\"DarkCyan\">" + snapshot.disappeared() + "</font>"
                + "; P1 в очереди: <font color=\"DarkCyan\">" + snapshot.p1Queued()
                + "</font> (open: " + snapshot.p1Open() + ")");
        if (applyResult == null) {
            return;
        }
        progress.line("Apply: DbtValue tail=<b><font color=\"DarkGreen\">" + applyResult.insertedValues()
                + "</font></b>; P1 rebuild=<b><font color=\"DarkGreen\">" + applyResult.p1Queued()
                + "</font></b>; tail ambiguous пропущено=<b><font color=\"Salmon\">"
                + applyResult.skippedTailAmbiguous() + "</font></b>");
    }
}
