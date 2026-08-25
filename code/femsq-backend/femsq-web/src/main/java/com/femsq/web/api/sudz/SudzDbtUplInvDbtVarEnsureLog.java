package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarAmbiguousRow;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtVarEnsureRow;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code invDbtVarEnsure}.
 */
public final class SudzDbtUplInvDbtVarEnsureLog {

    private SudzDbtUplInvDbtVarEnsureLog() {
    }

    /**
     * Пишет missing / ambiguous и итог apply.
     *
     * @param progress лог
     * @param missingRows однозначные без {@code invDbtVar}
     * @param ambiguousRows неоднозначные FK
     * @param applyResult итог apply или null
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            List<SudzDbtUplInvDbtVarEnsureRow> missingRows,
            List<SudzDbtUplInvDbtVarAmbiguousRow> ambiguousRows,
            SudzDbtUplInvDbtVarEnsureApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(missingRows, "missingRows");
        Objects.requireNonNull(ambiguousRows, "ambiguousRows");
        if (missingRows.isEmpty()) {
            progress.line("Отсутствующие однозначные контексты invDbtVar: "
                    + "<font color=\"Goldenrod\">нет</font>.");
        } else {
            progress.open("Отсутствуют однозначные invDbtVar: <font color=\"CadetBlue\">"
                    + missingRows.size() + "</font>", false);
            for (int i = 0; i < missingRows.size(); i++) {
                progress.line(formatMissing(i + 1, missingRows.get(i)));
            }
            progress.close();
        }
        if (ambiguousRows.isEmpty()) {
            progress.line("Неоднозначные резолвы cnNum/invNum: "
                    + "<font color=\"Goldenrod\">нет</font>.");
        } else {
            progress.open("Неоднозначные резолвы: <font color=\"Salmon\">"
                    + ambiguousRows.size() + "</font> (в очередь разбора при invDbtLoad)", false);
            for (int i = 0; i < ambiguousRows.size(); i++) {
                progress.line(formatAmbiguous(i + 1, ambiguousRows.get(i)));
            }
            progress.close();
        }
        if (applyResult != null) {
            progress.line("Внесено вариантов invDbtVar: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>.");
        }
    }

    static String formatMissing(int index, SudzDbtUplInvDbtVarEnsureRow row) {
        Objects.requireNonNull(row, "row");
        return "<font color=\"silver\">" + index + ". Договор <font color=\"CadetBlue\"><b>"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName()))
                + "</b></font>. СФ <font color=\"DarkSlateBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnInv()))
                + "</font>. iKey <font color=\"DarkViolet\">" + row.iKey()
                + "</font>. СГК <font color=\"DarkGoldenrod\">" + row.accountNum()
                + "</font>. account_key <font color=\"DarkViolet\">" + row.accountKey()
                + "</font>. cnnKey <font color=\"DarkViolet\">" + row.cnnKey()
                + "</font>. inKey <font color=\"DarkViolet\">" + row.inKey()
                + "</font>. cn_s_org <font color=\"DarkViolet\">" + row.cnSOrgKey()
                + "</font></font>.";
    }

    static String formatAmbiguous(int index, SudzDbtUplInvDbtVarAmbiguousRow row) {
        Objects.requireNonNull(row, "row");
        return "<font color=\"silver\">" + index + ". Договор <font color=\"CadetBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName()))
                + "</font>. СФ <font color=\"DarkSlateBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnInv()))
                + "</font>. iKey <font color=\"DarkViolet\">" + row.iKey()
                + "</font>. причина <font color=\"Salmon\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.reason()))
                + "</font></font>.";
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
