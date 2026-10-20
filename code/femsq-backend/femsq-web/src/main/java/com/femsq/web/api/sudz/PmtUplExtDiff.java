package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplExtDiff;
import com.femsq.database.model.sudz.SudzPmtUplExtGap;
import com.femsq.database.model.sudz.SudzPmtUplExtLine;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Построчное отличие книги (Tbl) и {@code cn_inv_pm}: семь сумм, срок, выравнивание и код стройки.
 * Пары строятся без стройки, затем сравнивается код. Запись в базу не выполняет.
 */
public final class PmtUplExtDiff {

    static final int MAX_SHOWN = 80;

    private static final Comparator<SudzPmtUplExtLine> BY_CAC = Comparator.comparing(
            line -> normCac(line.cac()),
            Comparator.nullsLast(String::compareTo));

    private PmtUplExtDiff() {
    }

    /**
     * Сравнивает мультимножества. Отличие стройки остаётся отличием, даже если суммы совпали.
     *
     * @param book строки книги
     * @param db платежи пакета
     * @return счётчики и первые отличия
     */
    public static SudzPmtUplExtDiff compare(List<SudzPmtUplExtLine> book, List<SudzPmtUplExtLine> db) {
        List<SudzPmtUplExtLine> bookRows = book == null ? List.of() : book;
        List<SudzPmtUplExtLine> dbRows = db == null ? List.of() : db;
        Map<String, List<SudzPmtUplExtLine>> bookGroups = group(bookRows);
        Map<String, List<SudzPmtUplExtLine>> dbGroups = group(dbRows);
        Set<String> keys = new LinkedHashSet<>();
        keys.addAll(bookGroups.keySet());
        keys.addAll(dbGroups.keySet());
        List<SudzPmtUplExtGap> gaps = new ArrayList<>();
        for (String key : keys) {
            List<SudzPmtUplExtLine> bookSide = new ArrayList<>(bookGroups.getOrDefault(key, List.of()));
            List<SudzPmtUplExtLine> dbSide = new ArrayList<>(dbGroups.getOrDefault(key, List.of()));
            bookSide.sort(BY_CAC);
            dbSide.sort(BY_CAC);
            int paired = Math.min(bookSide.size(), dbSide.size());
            for (int i = 0; i < paired; i++) {
                String bookCac = normCac(bookSide.get(i).cac());
                String dbCac = normCac(dbSide.get(i).cac());
                if (!Objects.equals(bookCac, dbCac)) {
                    gaps.add(gap(bookSide.get(i), "стройка", bookCac, dbCac));
                }
            }
            for (int i = paired; i < bookSide.size(); i++) {
                gaps.add(gap(bookSide.get(i), "строка", "есть", "нет"));
            }
            for (int i = paired; i < dbSide.size(); i++) {
                gaps.add(gap(dbSide.get(i), "строка", "нет", "есть"));
            }
        }
        int shown = Math.min(gaps.size(), MAX_SHOWN);
        return new SudzPmtUplExtDiff(
                bookRows.size(),
                dbRows.size(),
                gaps.size(),
                List.copyOf(gaps.subList(0, shown)));
    }

    private static Map<String, List<SudzPmtUplExtLine>> group(List<SudzPmtUplExtLine> rows) {
        Map<String, List<SudzPmtUplExtLine>> groups = new LinkedHashMap<>();
        for (SudzPmtUplExtLine row : rows) {
            groups.computeIfAbsent(key(row), ignored -> new ArrayList<>()).add(row);
        }
        return groups;
    }

    private static SudzPmtUplExtGap gap(
            SudzPmtUplExtLine row, String field, String bookValue, String dbValue) {
        return new SudzPmtUplExtGap(
                row.docCode() == null ? "" : row.docCode().trim(),
                row.sheet(),
                stamp(row.due()),
                field,
                bookValue,
                dbValue);
    }

    private static String key(SudzPmtUplExtLine row) {
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
        return value.setScale(4, RoundingMode.HALF_UP).toPlainString();
    }

    private static String normCac(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
