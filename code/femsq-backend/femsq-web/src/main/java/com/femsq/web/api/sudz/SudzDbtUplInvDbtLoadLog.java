package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplInvDbtLoadCalmRow;
import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code invDbtLoad} (очередь, calm-снимок, apply).
 */
public final class SudzDbtUplInvDbtLoadLog {

    /** Максимум строк Excel в раскрытом блоке лога. */
    static final int LOG_ROW_CAP = 40;

    private SudzDbtUplInvDbtLoadLog() {
    }

    /**
     * Пишет размер очереди, снимок Calm Create / F1 / тихой дыры и итог auto-apply.
     *
     * @param progress лог
     * @param applyResult итог фазы (всегда не null после runInvDbtLoadPhase)
     * @param flLoad был ли apply
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            SudzDbtUplInvDbtLoadApplyResult applyResult,
            boolean flLoad
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(applyResult, "applyResult");
        int queuedCount = applyResult.queuedCount();
        if (queuedCount <= 0) {
            progress.line("Очередь разбора двоящих задолженностей: "
                    + "<font color=\"Goldenrod\">пуста</font>.");
        } else {
            progress.line("В очередь разбора поставлено: <font color=\"CadetBlue\"><b>"
                    + queuedCount + "</font></b> строк"
                    + " (экран «Разбор двоящих задолженностей СФ»).");
        }
        appendCalmBlock(
                progress,
                "Calm Create (слот invDbt ещё нет — будет создан при «Обновлять»)",
                applyResult.calmCreatePending(),
                "CadetBlue",
                flLoad);
        appendCalmBlock(
                progress,
                "Calm F1 (мост/Value на существующий слот)",
                applyResult.calmF1Pending(),
                "DarkCyan",
                flLoad);
        appendCalmBlock(
                progress,
                "Тихая дыра (4FK+var, слотов 0, не calm и не очередь)",
                applyResult.silentHoleResolved(),
                "Salmon",
                flLoad);
        if (flLoad) {
            progress.line("Auto invDbt: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedInvDbt()
                    + "</font></b>; мостов invDbtDbtVar: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedBridges()
                    + "</font></b>; DbtValue: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedValues() + "</font></b>.");
        } else {
            progress.line("<font color=\"Goldenrod\">dry-run</font> — в домен не писали"
                    + " (включите «Обновлять» для apply).");
        }
    }

    /**
     * Совместимость со старым вызовом (очередь + apply без явного flLoad).
     *
     * @param progress лог
     * @param queuedCount игнорируется, берётся из applyResult
     * @param applyResult итог
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            int queuedCount,
            SudzDbtUplInvDbtLoadApplyResult applyResult
    ) {
        Objects.requireNonNull(applyResult, "applyResult");
        boolean flLoad = applyResult.insertedInvDbt() > 0
                || applyResult.insertedBridges() > 0
                || applyResult.insertedValues() > 0;
        append(progress, applyResult, flLoad);
    }

    private static void appendCalmBlock(
            SudzDbtUplProgressLog progress,
            String title,
            List<SudzDbtUplInvDbtLoadCalmRow> rows,
            String countColor,
            boolean flLoad
    ) {
        if (rows.isEmpty()) {
            progress.line(title + ": <font color=\"Goldenrod\">нет</font>.");
            return;
        }
        String dryHint = flLoad ? "" : " <font color=\"Goldenrod\">(dry — не записано)</font>";
        progress.open(title + ": <font color=\"" + countColor + "\"><b>"
                + rows.size() + "</b></font>" + dryHint, false);
        int limit = Math.min(rows.size(), LOG_ROW_CAP);
        for (int i = 0; i < limit; i++) {
            progress.line(formatRow(i + 1, rows.get(i)));
        }
        if (rows.size() > LOG_ROW_CAP) {
            progress.line("<font color=\"silver\">… и ещё "
                    + (rows.size() - LOG_ROW_CAP) + "</font>.");
        }
        progress.close();
    }

    static String formatRow(int index, SudzDbtUplInvDbtLoadCalmRow row) {
        Objects.requireNonNull(row, "row");
        String debt = row.debt() == null ? "" : formatDebt(row.debt());
        return "<font color=\"silver\">" + index + ". Договор <font color=\"CadetBlue\"><b>"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnName()))
                + "</b></font>. СФ <font color=\"DarkSlateBlue\">"
                + SudzDbtUplProgressLog.escape(nullToEmpty(row.cnInv()))
                + "</font>. сумма <font color=\"DarkGoldenrod\">" + debt
                + "</font>. cidut <font color=\"DarkViolet\">"
                + (row.cidutKey() == null ? "—" : row.cidutKey())
                + "</font>. iKey <font color=\"DarkViolet\">" + row.iKey()
                + "</font>. idvvKey <font color=\"DarkViolet\">"
                + (row.idvvKey() == null ? "—" : row.idvvKey())
                + "</font></font>.";
    }

    private static String formatDebt(BigDecimal debt) {
        return debt.stripTrailingZeros().toPlainString();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
