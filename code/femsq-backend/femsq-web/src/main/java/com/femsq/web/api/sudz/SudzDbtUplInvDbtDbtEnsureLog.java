package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtDbtEnsureSnapshot;
import java.util.Objects;

/**
 * HTML-лог шага {@code invDbtDbtEnsure} (C1).
 */
public final class SudzDbtUplInvDbtDbtEnsureLog {

    private SudzDbtUplInvDbtDbtEnsureLog() {
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
            SudzDbtUplInvDbtDbtEnsureSnapshot snapshot,
            SudzDbtUplInvDbtDbtEnsureApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(snapshot, "snapshot");
        if (snapshot.missingBridge() == 0) {
            progress.line("<font color=\"DarkGreen\">все слоты upl уже имеют invDbtDbt</font>");
            return;
        }
        progress.line("Без моста invDbtDbt: <font color=\"DarkCyan\">"
                + snapshot.missingBridge() + "</font>"
                + " (F1 reuse: " + snapshot.f1Ready()
                + ", новый Dbt: " + snapshot.newReady()
                + ", ambiguous: " + snapshot.ambiguous() + ")");
        if (applyResult == null) {
            return;
        }
        progress.line("Apply: reuse F1=<b><font color=\"DarkGreen\">" + applyResult.reusedF1()
                + "</font></b>; новых Dbt=<b><font color=\"DarkGreen\">" + applyResult.insertedDbt()
                + "</font></b>; мостов=<b><font color=\"DarkGreen\">" + applyResult.insertedBridges()
                + "</font></b>; пропущено ambiguous=<b><font color=\"Salmon\">"
                + applyResult.skippedAmbiguous() + "</font></b>");
    }
}
