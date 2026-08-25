package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import java.util.Objects;

/**
 * HTML-лог шага {@code invDbtLoad}.
 */
public final class SudzDbtUplInvDbtLoadLog {

    private SudzDbtUplInvDbtLoadLog() {
    }

    /**
     * Пишет размер очереди и итог auto-apply.
     *
     * @param progress лог
     * @param queuedCount число строк {@code CnInvUplInvDbtDouble}
     * @param applyResult итог apply или null (dry-run)
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            int queuedCount,
            SudzDbtUplInvDbtLoadApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        if (queuedCount <= 0) {
            progress.line("Очередь разбора двоящих задолженностей: "
                    + "<font color=\"Goldenrod\">пуста</font>.");
        } else {
            progress.line("В очередь разбора поставлено: <font color=\"CadetBlue\"><b>"
                    + queuedCount + "</font></b> строк"
                    + " (экран «Разбор двоящих задолженностей СФ»).");
        }
        if (applyResult != null) {
            progress.line("Auto invDbt: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedInvDbt()
                    + "</font></b>; мостов invDbtDbtVar: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedBridges() + "</font></b>.");
        }
    }
}
