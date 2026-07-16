package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.staging.StagingLogLevel;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Форматирование строк NEW/CHANGED для дерева сверки type=5 (§9.3.8.2).
 * <p>
 * SUMMARY — первые {@link #SUMMARY_LINE_LIMIT} строк + «и ещё N»; VERBOSE — полный список;
 * MINIMAL — списки не пишутся.
 * </p>
 */
public final class Type5ReconcileTreeLineFormatter {

    /** Лимит строк NEW/CHANGED в ветке при {@link StagingLogLevel#SUMMARY}. */
    public static final int SUMMARY_LINE_LIMIT = 40;

    private static final DateTimeFormatter RU_DATE = DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final String HTML_CRIMSON = "#DC143C";
    private static final String HTML_PERU = "#CD853F";
    private static final String HTML_SEA_GREEN = "#2E8B57";

    private Type5ReconcileTreeLineFormatter() {
    }

    /**
     * Лимит детальных строк дерева по уровню лога.
     *
     * @param level уровень staging/reconcile лога
     * @return {@link Integer#MAX_VALUE} для VERBOSE, {@link #SUMMARY_LINE_LIMIT} для SUMMARY, 0 для MINIMAL/null
     */
    public static int detailLimit(StagingLogLevel level) {
        if (level == null || level == StagingLogLevel.MINIMAL) {
            return 0;
        }
        if (level == StagingLogLevel.VERBOSE) {
            return Integer.MAX_VALUE;
        }
        return SUMMARY_LINE_LIMIT;
    }

    /**
     * Обрезает список строк по лимиту; хвост учитывается в {@code suppressed}.
     *
     * @param allLines все HTML-абзацы в порядке индексации
     * @param limit    макс. число показанных строк (0 — ничего не показывать)
     * @return блок для вложения в span «готово к внесению» / «внесено»
     */
    public static Type5ReconcileTreeLogger.ListedBlock limitLines(List<String> allLines, int limit) {
        if (allLines == null || allLines.isEmpty() || limit <= 0) {
            int suppressed = allLines == null ? 0 : allLines.size();
            return new Type5ReconcileTreeLogger.ListedBlock(List.of(), suppressed);
        }
        if (allLines.size() <= limit) {
            return new Type5ReconcileTreeLogger.ListedBlock(List.copyOf(allLines), 0);
        }
        List<String> shown = new ArrayList<>(allLines.subList(0, limit));
        return new Type5ReconcileTreeLogger.ListedBlock(List.copyOf(shown), allLines.size() - limit);
    }

    /**
     * Строка NEW отчёта (Access SCR-002-A, без ключа домена — dry-run / до apply).
     *
     * @param index    1-based порядковый номер в списке
     * @param excelRow Excel 1-based или {@code null}
     * @param raNum    номер ОА
     * @param raDate   дата ОА
     * @param ttl      сумма
     * @param work     СМР
     * @param equip    оборудование
     * @param others   прочие
     * @return HTML {@code <P>…</P>}
     */
    public static String formatRaNewLine(
            int index,
            Integer excelRow,
            String raNum,
            LocalDate raDate,
            BigDecimal ttl,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
        StringBuilder sb = new StringBuilder();
        sb.append("<P>").append(index).append(". ").append(rowLabel(excelRow)).append(". ");
        sb.append(escape(nullToDash(raNum))).append(" от ").append(formatDate(raDate)).append(". ");
        sb.append(formatSumsPhrase(ttl, work, equip, others));
        sb.append("</P>");
        return sb.toString();
    }

    /**
     * Строка CHANGED отчёта с inline-diff полей (Access SCR-002-B).
     *
     * @param index    1-based
     * @param excelRow Excel-строка
     * @param raNum    номер ОА
     * @param diffs    отличия полей (может быть пусто — только заголовок)
     * @return HTML {@code <P>…</P>}
     */
    public static String formatRaChangedLine(int index, Integer excelRow, String raNum, List<FieldDiff> diffs) {
        StringBuilder sb = new StringBuilder();
        sb.append("<P>").append(index).append(". ").append(rowLabel(excelRow)).append(". ");
        sb.append(escape(nullToDash(raNum))).append(".");
        if (diffs != null) {
            for (FieldDiff diff : diffs) {
                if (diff == null) {
                    continue;
                }
                sb.append(' ').append(formatFieldDiff(diff));
            }
        }
        sb.append("</P>");
        return sb.toString();
    }

    /**
     * Строка NEW изменения (Access SCR-002-C).
     *
     * @param index       1-based
     * @param excelRow    Excel-строка
     * @param changeNum   номер изменения
     * @param reportNum   номер базового ОА
     * @param reportDate  дата базового ОА (из разбора)
     * @param changeDate  дата строки изменения
     * @param ttl         сумма
     * @param work        СМР
     * @param equip       оборудование
     * @param others      прочие
     * @return HTML
     */
    public static String formatRcNewLine(
            int index,
            Integer excelRow,
            String changeNum,
            String reportNum,
            LocalDate reportDate,
            LocalDate changeDate,
            BigDecimal ttl,
            BigDecimal work,
            BigDecimal equip,
            BigDecimal others
    ) {
        StringBuilder sb = new StringBuilder();
        sb.append("<P>").append(index).append(". ").append(rowLabel(excelRow)).append(". ");
        sb.append("Изм ").append(escape(nullToDash(changeNum)))
                .append(" к ОА № ").append(escape(nullToDash(reportNum)))
                .append(" от ").append(formatDate(reportDate));
        if (changeDate != null) {
            sb.append(" (изм. от ").append(formatDate(changeDate)).append(')');
        }
        sb.append(". ").append(formatSumsPhrase(ttl, work, equip, others));
        sb.append("</P>");
        return sb.toString();
    }

    /**
     * Строка CHANGED изменения с inline-diff.
     *
     * @param index      1-based
     * @param excelRow   Excel-строка
     * @param changeNum  номер изменения
     * @param reportHint краткое описание базы (№ ОА) или сырой rainRaNum
     * @param diffs      отличия
     * @return HTML
     */
    public static String formatRcChangedLine(
            int index,
            Integer excelRow,
            String changeNum,
            String reportHint,
            List<FieldDiff> diffs
    ) {
        StringBuilder sb = new StringBuilder();
        sb.append("<P>").append(index).append(". ").append(rowLabel(excelRow)).append(". ");
        sb.append("Изм ").append(escape(nullToDash(changeNum)));
        if (reportHint != null && !reportHint.isBlank()) {
            sb.append(" (").append(escape(reportHint.trim())).append(')');
        }
        sb.append('.');
        if (diffs != null) {
            for (FieldDiff diff : diffs) {
                if (diff == null) {
                    continue;
                }
                sb.append(' ').append(formatFieldDiff(diff));
            }
        }
        sb.append("</P>");
        return sb.toString();
    }

    /**
     * Одно изменённое поле: «метка, БД: old; источник: new. Обновлено, БД: new».
     *
     * @param label человекочитаемое имя поля
     * @param oldVal значение в БД
     * @param newVal значение из источника
     */
    public record FieldDiff(String label, String oldVal, String newVal) {
    }

    private static String formatFieldDiff(FieldDiff diff) {
        String oldDisp = escape(nullToDash(diff.oldVal()));
        String newDisp = escape(nullToDash(diff.newVal()));
        return "<font color=\"" + HTML_CRIMSON + "\">" + escape(diff.label()) + ", БД: " + oldDisp
                + "</font>; <font color=\"" + HTML_PERU + "\">источник: " + newDisp
                + "</font>. <font color=\"" + HTML_SEA_GREEN + "\">Обновлено, БД: " + newDisp + "</font>.";
    }

    private static String formatSumsPhrase(BigDecimal ttl, BigDecimal work, BigDecimal equip, BigDecimal others) {
        if (isBlankMoney(ttl) && isBlankMoney(work) && isBlankMoney(equip) && isBlankMoney(others)) {
            return "Сумма не требуется.";
        }
        return "Сумма: всего: " + money(ttl) + " Р, СМР: " + money(work)
                + " Р, Оборудование: " + money(equip) + " Р, Прочие: " + money(others) + " Р.";
    }

    private static boolean isBlankMoney(BigDecimal v) {
        return v == null || v.compareTo(BigDecimal.ZERO) == 0;
    }

    private static String money(BigDecimal v) {
        if (v == null) {
            return "";
        }
        return escape(v.stripTrailingZeros().toPlainString());
    }

    private static String rowLabel(Integer excelRow) {
        return excelRow != null ? String.valueOf(excelRow) : "—";
    }

    private static String formatDate(LocalDate d) {
        return d == null ? "—" : d.format(RU_DATE);
    }

    private static String nullToDash(String s) {
        return s == null || s.isBlank() ? "—" : s.trim();
    }

    private static String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    /**
     * Добавляет diff, если значения отличаются.
     *
     * @param target список
     * @param label  метка
     * @param oldVal БД
     * @param newVal источник
     */
    public static void addDiffIfChanged(List<FieldDiff> target, String label, String oldVal, String newVal) {
        String o = normalize(oldVal);
        String n = normalize(newVal);
        if (Objects.equals(o, n)) {
            return;
        }
        target.add(new FieldDiff(label, o == null ? "—" : o, n == null ? "—" : n));
    }

    private static String normalize(String v) {
        if (v == null || v.isBlank() || "—".equals(v)) {
            return null;
        }
        return v.trim();
    }
}
