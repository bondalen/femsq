package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplInsPmNotApplyResult;
import com.femsq.database.model.sudz.SudzPmtUplInsPmNotResult;
import java.util.Objects;

/**
 * HTML-лог шага 12 платежей {@code cipuInsPmNotLoad} (сводка N, как Access VBA).
 */
public final class SudzPmtUplInsPmNotLoadLog {

    private SudzPmtUplInsPmNotLoadLog() {
    }

    /**
     * Пишет сводку готовых платежей; при apply — число INSERT.
     *
     * @param progress лог
     * @param find итог find
     * @param applyResult итог INSERT или {@code null}
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            SudzPmtUplInsPmNotResult find,
            SudzPmtUplInsPmNotApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(find, "find");
        if (applyResult != null) {
            progress.line("Внесено платежи в количестве: <font color=\"DarkGreen\"><b>"
                    + applyResult.insertedCount() + "</b></font> записей.");
        }
        if (find.readyCount() <= 0) {
            progress.line("В источнике <font color=\"Olive\">отсутствуют платежи, отстутствующие в БД, "
                    + "<b>готовые к внесению</b></font>.");
            return;
        }
        progress.line("В источнике <font color=\"CadetBlue\">имеются платежи</font>"
                + " , отстутствующие в БД <font color=\"DarkGreen\"><b>готовые к внесению</b></font>. "
                + "В количестве " + find.readyCount() + ".");
    }
}
