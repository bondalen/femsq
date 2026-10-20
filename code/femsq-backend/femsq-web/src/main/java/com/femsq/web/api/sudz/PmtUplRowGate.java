package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplLine;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Сверка набора строк книги (Tbl с «№ докум.») и платежей пакета.
 * Совпадает число копий одного ключа: документ, лист, срок, дата выравнивания и семь сумм.
 */
final class PmtUplRowGate {

    private static final int MAX_GAP_LINES = 40;

    /**
     * @param matched true, если наборы совпали
     * @param lines строки для лога прогона
     */
    record Verdict(boolean matched, List<String> lines) {
    }

    private PmtUplRowGate() {
    }

    /**
     * Сравнивает мультимножества строк.
     *
     * @param book строки книги
     * @param db платежи пакета
     * @return вердикт и строки лога
     */
    static Verdict compare(List<SudzPmtUplLine> book, List<SudzPmtUplLine> db) {
        if (book == null || book.isEmpty()) {
            return new Verdict(false, List.of(
                    "Сверка строк: в книге (Tbl, строки с «№ докум.») нет строк."));
        }
        Map<String, Integer> bookN = counts(book);
        Map<String, Integer> dbN = counts(db == null ? List.of() : db);
        List<String> gaps = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : bookN.entrySet()) {
            int have = dbN.getOrDefault(entry.getKey(), 0);
            int delta = entry.getValue() - have;
            if (delta > 0) {
                gaps.add("нет в базе ×" + delta + ": " + entry.getKey());
            }
        }
        for (Map.Entry<String, Integer> entry : dbN.entrySet()) {
            int have = bookN.getOrDefault(entry.getKey(), 0);
            int delta = entry.getValue() - have;
            if (delta > 0) {
                gaps.add("лишняя в базе ×" + delta + ": " + entry.getKey());
            }
        }
        if (gaps.isEmpty()) {
            return new Verdict(true, List.of(
                    "Сверка строк с книгой: совпало (строк <b>" + book.size() + "</b>)."));
        }
        List<String> lines = new ArrayList<>();
        lines.add("Сверка строк с книгой: расхождение. Книга <b>" + book.size()
                + "</b>, база <b>" + (db == null ? 0 : db.size()) + "</b>.");
        int shown = Math.min(gaps.size(), MAX_GAP_LINES);
        lines.addAll(gaps.subList(0, shown));
        if (gaps.size() > shown) {
            lines.add("… ещё расхождений: <b>" + (gaps.size() - shown) + "</b>.");
        }
        return new Verdict(false, List.copyOf(lines));
    }

    private static Map<String, Integer> counts(List<SudzPmtUplLine> rows) {
        Map<String, Integer> counts = new HashMap<>();
        for (SudzPmtUplLine row : rows) {
            String key = key(row);
            counts.merge(key, 1, Integer::sum);
        }
        return counts;
    }

    private static String key(SudzPmtUplLine row) {
        return (row.docCode() == null ? "" : row.docCode().trim())
                + "|" + (row.sheet() == null ? "" : row.sheet())
                + "|" + stamp(row.due())
                + "|" + stamp(row.alignment())
                + "|" + money(row.dbtBlns())
                + "|" + money(row.dbtBlnsOverd())
                + "|" + money(row.dbtBlnsNotOverd())
                + "|" + money(row.cdtBlns())
                + "|" + money(row.cdtBlnsOverd())
                + "|" + money(row.cdtBlnsNotOverd())
                + "|" + money(row.blns());
    }

    private static String stamp(LocalDateTime value) {
        if (value == null) {
            return "";
        }
        return value.truncatedTo(ChronoUnit.SECONDS).toString();
    }

    private static String money(BigDecimal value) {
        if (value == null) {
            return "0.0000";
        }
        return value.setScale(4, java.math.RoundingMode.HALF_UP).toPlainString();
    }
}
