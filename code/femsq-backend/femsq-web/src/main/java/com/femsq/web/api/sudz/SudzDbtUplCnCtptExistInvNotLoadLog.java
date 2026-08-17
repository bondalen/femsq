package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvContract;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvItem;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvResult;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага {@code CnCtptExistInvNotLoad}
 * (зеркало Access {@code CnCtptExistInvNot} / {@code CnInvConcat}).
 */
public final class SudzDbtUplCnCtptExistInvNotLoadLog {

    private static final String NULL_OR_EMPTY = "NullИлиПусто";

    private SudzDbtUplCnCtptExistInvNotLoadLog() {
    }

    /**
     * Пишет заголовок и строки договоров с перечнем СФ.
     *
     * @param progress лог
     * @param prepared буфер/контракты
     * @param applyResult итог apply или null
     */
    public static void append(
            SudzDbtUplProgressLog progress,
            SudzDbtUplCnCtptExistInvResult prepared,
            SudzDbtUplCnCtptExistInvApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(prepared, "prepared");
        List<SudzDbtUplCnCtptExistInvContract> contracts = prepared.contracts();
        if (contracts.isEmpty()) {
            progress.line("В источнике <font color=\"Goldenrod\">отсутствуют договора,"
                    + " имеющие счета-фактуры отсутствующие в БД</font>.");
        } else {
            progress.line("В источнике <font color=\"CadetBlue\">имеются договора</font>, ("
                    + contracts.size()
                    + ") к которым <font color=\"Goldenrod\">имеются счета-фактуры отсутствующие в БД</font> ("
                    + prepared.invoiceRowCount() + ").");
            int index = 1;
            for (SudzDbtUplCnCtptExistInvContract contract : contracts) {
                progress.line(formatContract(index, contract));
                index++;
            }
        }
        if (applyResult != null) {
            progress.line("Внесено счетов-фактур (строк) в БД: <b><font color=\"DarkGreen\">"
                    + applyResult.insertedCount() + "</font></b>");
        }
    }

    /**
     * Одна строка договора + склейка СФ.
     *
     * @param index номер с 1
     * @param contract договор
     * @return HTML
     */
    static String formatContract(int index, SudzDbtUplCnCtptExistInvContract contract) {
        Objects.requireNonNull(contract, "contract");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\">Договор: <font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. № договора: <font color=\"CadetBlue\"><b>")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(contract.cnName())))
                .append("</b></font>. CnId: <font color=\"DarkViolet\">")
                .append(contract.cnKey())
                .append("</font>. Всего: <b><font color=\"DarkGoldenrod\">")
                .append(contract.invCount())
                .append("</font></b>. Счета-фактуры: <font color=\"DarkGray\">")
                .append(formatInvoices(contract.invoices()))
                .append("</font></font>.");
        return html.toString();
    }

    /** В HTML-логе — первые MAX_INV_IN_LOG СФ; полный список остаётся в буфере. */
    private static final int MAX_INV_IN_LOG = 8;

    private static String formatInvoices(List<SudzDbtUplCnCtptExistInvItem> invoices) {
        if (invoices == null || invoices.isEmpty()) {
            return "*нет записей*";
        }
        StringBuilder sb = new StringBuilder();
        int shown = Math.min(invoices.size(), MAX_INV_IN_LOG);
        for (int i = 0; i < shown; i++) {
            if (i > 0) {
                sb.append("; ");
            }
            sb.append("<font color=\"MediumOrchid\">").append(i + 1).append("</font>. ");
            sb.append(formatOneInv(invoices.get(i)));
        }
        if (invoices.size() > MAX_INV_IN_LOG) {
            sb.append("; … ещё ").append(invoices.size() - MAX_INV_IN_LOG);
        }
        return sb.toString();
    }

    private static String formatOneInv(SudzDbtUplCnCtptExistInvItem item) {
        String raw = item.cnInv();
        boolean empty = raw == null || raw.isBlank() || NULL_OR_EMPTY.equals(raw);
        String body = empty
                ? "*<font color=\"DarkOrange\">пустая строка</font>*"
                : SudzDbtUplProgressLog.escape(raw);
        if (item.inNumCount() != null) {
            body = body + " {<font color=\"Salmon\">встречался " + item.inNumCount() + " раз(а)</font>}";
        }
        return body;
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
