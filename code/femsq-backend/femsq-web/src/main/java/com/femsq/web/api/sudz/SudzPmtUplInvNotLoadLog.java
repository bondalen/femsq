package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvApplyResult;
import com.femsq.database.model.sudz.SudzDbtUplCnCtptExistInvItem;
import com.femsq.database.model.sudz.SudzPmtUplInvNotContract;
import com.femsq.database.model.sudz.SudzPmtUplInvNotResult;
import java.util.List;
import java.util.Objects;

/**
 * HTML-лог шага 7 платежей {@code cipuCn_CtptCnOneInvNotLoad}
 * (зеркало Access {@code cipuCn_CtptCnOneInvNot} / {@code CnInvConcatPm}).
 */
public final class SudzPmtUplInvNotLoadLog {

    private static final String NULL_OR_EMPTY = "NullИлиПусто";
    private static final int MAX_INV_IN_LOG = 8;

    private SudzPmtUplInvNotLoadLog() {
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
            SudzPmtUplInvNotResult prepared,
            SudzDbtUplCnCtptExistInvApplyResult applyResult
    ) {
        Objects.requireNonNull(progress, "progress");
        Objects.requireNonNull(prepared, "prepared");
        List<SudzPmtUplInvNotContract> contracts = prepared.contracts();
        if (contracts.isEmpty()) {
            progress.line("В источнике <font color=\"Olive\"><b>отсутствуют договора,"
                    + " имеющие счета-фактуры отсутствующие в БД</b></font>.");
        } else {
            progress.line("В источнике <font color=\"CadetBlue\">имеются договора</font>, ("
                    + contracts.size()
                    + ") к которым <font color=\"Goldenrod\">имеются счета-фактуры отсутствующие в БД</font> ("
                    + prepared.invoiceRowCount() + ").");
            int index = 1;
            for (SudzPmtUplInvNotContract contract : contracts) {
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
     * Одна строка договора + склейка СФ (Access: БУиРГ + имя + № дг.).
     *
     * @param index номер с 1
     * @param contract договор
     * @return HTML
     */
    static String formatContract(int index, SudzPmtUplInvNotContract contract) {
        Objects.requireNonNull(contract, "contract");
        StringBuilder html = new StringBuilder();
        html.append("<font color=\"silver\"><font color=\"DarkSlateBlue\">")
                .append(index)
                .append("</font>. <font color=\"CadetBlue\">")
                .append(SudzDbtUplProgressLog.escape(nullToEmpty(contract.name())))
                .append("</font>. БУиРГ: <font color=\"DarkCyan\">")
                .append(contract.buirg() == null ? "—" : contract.buirg())
                .append("</font>. № дг.: <font color=\"CadetBlue\"><b>")
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
