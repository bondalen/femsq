package com.femsq.web.audit.reconcile;

import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.Month;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Разбор поля {@code rainRaNum} для строк со знаком «ОА изм» (ветка изменений), по логике VBA
 * {@code RcStringNum} / {@code RcStringRaNum} / {@code RcStringRaDate} и {@code ParseDate} ({@code Module1.bas}).
 *
 * <p>Даты: форматы {@code dd.MM.yyyy} / {@code dd.MM.yy} и текстовый вид {@code dd месяц yyyy} /
 * {@code "dd" месяц yyyy} (русские названия месяцев, регистр как в VBA).</p>
 */
final class RcStagingLineParser {

    /** Как в VBA, но без привязки к регистру кириллицы (в Excel встречается «ИЗМ», «ИЗМЕНЕНИЕ»). */
    private static final Pattern CHANGE_HEAD = Pattern.compile(
            "(Изм|изм|Изменение|изменение)(\\.|\\s\\.)*(№| №)*(\\s)*([0-9]{1,3})",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    /**
     * Как в VBA {@code ParseDate}: {@code dd.MM.yy} с необязательным хвостом после двух цифр года, либо {@code dd.MM.yyyy}.
     */
    private static final Pattern DOT_DATE = Pattern.compile("\\d{2}\\.\\d{2}\\.(?:\\d{4}|\\d{2}(?:\\D|$))");

    /**
     * Вторая ветка {@code ParseDate}: {@code 15 июня 2024} или {@code "15" июня 2024}.
     */
    private static final Pattern RUSSIAN_TEXT_DATE = Pattern.compile(
            "(?:\"(\\d{2})\"|(?<![0-9])(\\d{2})(?![0-9]))\\s+"
                    + "([яЯ]нваря|[фФ]евраля|[мМ]арта|[аА]преля|[мМ]ая|[иИ]юня|[иИ]юля|[аА]вгуста|[сС]ентября|[оО]ктября|[нН]оября|[дД]екабря)"
                    + "\\s+(\\d{4})");

    private static final Locale RU = Locale.forLanguageTag("ru");

    private RcStagingLineParser() {
    }

    /**
     * @param rainRaNum сырое значение из staging (как в Excel)
     * @return номер изменения, номер отчёта (фрагмент с дефисом), самая ранняя дата в строке — если строка распознана как «изменение»
     */
    static Optional<ParsedRcLine> parse(String rainRaNum) {
        String cleaned = stringClean(rainRaNum);
        if (cleaned.isEmpty()) {
            return Optional.empty();
        }
        boolean isChange = containsIzmenenieToken(cleaned);
        if (!isChange) {
            return Optional.empty();
        }
        Integer changeNum = extractChangeNumber(cleaned);
        if (changeNum == null || changeNum <= 0) {
            return Optional.empty();
        }
        String reportNum = extractReportNumberToken(cleaned);
        if (reportNum == null) {
            return Optional.empty();
        }
        LocalDate reportDate = findEarliestDate(cleaned).orElse(null);
        if (reportDate == null) {
            return Optional.empty();
        }
        return Optional.of(new ParsedRcLine(changeNum, reportNum, reportDate));
    }

    private static String stringClean(String text) {
        if (text == null) {
            return "";
        }
        String t = text.replace('\r', ' ')
                .replace('\n', ' ')
                .replace('\t', ' ')
                .replace('\u0000', ' ')
                .replace('\u00A0', ' ');
        while (t.contains("  ")) {
            t = t.replace("  ", " ");
        }
        t = t.trim();
        return t;
    }

    /** Токены по пробелам и типичным разделителям в Excel-текстах (доп. к VBA {@code Split} по пробелу). */
    private static String[] splitTokens(String cleaned) {
        return cleaned.split("[\\s,;:]+");
    }

    private static boolean containsIzmenenieToken(String cleaned) {
        for (String token : splitTokens(cleaned)) {
            if (token.toLowerCase(RU).contains("изм")) {
                return true;
            }
        }
        return false;
    }

    private static Integer extractChangeNumber(String cleaned) {
        Matcher head = CHANGE_HEAD.matcher(cleaned);
        if (head.find()) {
            String group = head.group(5);
            if (group != null && !group.isEmpty()) {
                try {
                    return Integer.parseInt(group);
                } catch (NumberFormatException ignored) {
                    // fall through to word scan
                }
            }
        }
        for (String raw : splitTokens(cleaned)) {
            String token = raw;
            if (token.startsWith("№") && token.length() > 1) {
                token = token.substring(1);
            }
            if (token.matches("[0-9]+")) {
                try {
                    return Integer.parseInt(token);
                } catch (NumberFormatException ignored) {
                    // continue
                }
            }
        }
        return null;
    }

    /**
     * После правки 17.04.2025 в VBA: токен с дефисом; при наличии {@code №} — отрезаем префикс.
     */
    private static String extractReportNumberToken(String cleaned) {
        for (String raw : splitTokens(cleaned)) {
            if (raw.contains("-")) {
                if (raw.startsWith("№") && raw.length() > 1) {
                    return raw.substring(1).trim();
                }
                return raw.trim();
            }
        }
        return null;
    }

    /**
     * Самая ранняя дата по всем совпадениям, как {@code ParseDate(..., Start=True)} в VBA.
     */
    private static Optional<LocalDate> findEarliestDate(String cleaned) {
        List<LocalDate> dates = new ArrayList<>();
        collectDotDates(cleaned, dates);
        collectRussianTextDates(cleaned, dates);
        return dates.stream().min(Comparator.naturalOrder());
    }

    private static void collectDotDates(String cleaned, List<LocalDate> out) {
        Matcher m = DOT_DATE.matcher(cleaned);
        while (m.find()) {
            String fragment = m.group();
            parseDotDateFragment(fragment).ifPresent(out::add);
        }
    }

    /**
     * VBA: при длине 9 обрезать до 8 символов (хвост после {@code dd.MM.yy}).
     */
    private static Optional<LocalDate> parseDotDateFragment(String raw) {
        String fragment = raw;
        if (fragment.length() == 9 && fragment.charAt(8) != '.') {
            fragment = fragment.substring(0, 8);
        }
        if (fragment.length() > 10) {
            fragment = fragment.substring(0, 10);
        }
        String[] patterns = {"dd.MM.uuuu", "dd.MM.uu"};
        for (String p : patterns) {
            try {
                DateTimeFormatter f = DateTimeFormatter.ofPattern(p, Locale.ROOT);
                return Optional.of(LocalDate.parse(fragment, f));
            } catch (DateTimeParseException ignored) {
                // try next
            }
        }
        return Optional.empty();
    }

    private static void collectRussianTextDates(String cleaned, List<LocalDate> out) {
        Matcher m = RUSSIAN_TEXT_DATE.matcher(cleaned);
        while (m.find()) {
            String dayQuoted = m.group(1);
            String dayPlain = m.group(2);
            String dayStr = dayQuoted != null ? dayQuoted : dayPlain;
            String monthWord = m.group(3);
            String yearStr = m.group(4);
            parseRussianDayMonthYear(dayStr, monthWord, yearStr).ifPresent(out::add);
        }
    }

    private static Optional<LocalDate> parseRussianDayMonthYear(String dayStr, String monthWord, String yearStr) {
        try {
            int day = Integer.parseInt(dayStr);
            int year = Integer.parseInt(yearStr);
            Month month = monthFromRussianName(monthWord);
            if (month == null || day < 1 || day > 31) {
                return Optional.empty();
            }
            return Optional.of(LocalDate.of(year, month, day));
        } catch (DateTimeException | NumberFormatException ignored) {
            return Optional.empty();
        }
    }

    private static Month monthFromRussianName(String token) {
        if (token == null || token.isEmpty()) {
            return null;
        }
        String m = token.toLowerCase(RU);
        if (m.startsWith("январ")) {
            return Month.JANUARY;
        }
        if (m.startsWith("феврал")) {
            return Month.FEBRUARY;
        }
        if (m.startsWith("март")) {
            return Month.MARCH;
        }
        if (m.startsWith("апрел")) {
            return Month.APRIL;
        }
        if (m.startsWith("мая") || m.startsWith("май")) {
            return Month.MAY;
        }
        if (m.startsWith("июня") || m.equals("июнь")) {
            return Month.JUNE;
        }
        if (m.startsWith("июля") || m.equals("июль")) {
            return Month.JULY;
        }
        if (m.startsWith("август")) {
            return Month.AUGUST;
        }
        if (m.startsWith("сентябр")) {
            return Month.SEPTEMBER;
        }
        if (m.startsWith("октябр")) {
            return Month.OCTOBER;
        }
        if (m.startsWith("ноябр")) {
            return Month.NOVEMBER;
        }
        if (m.startsWith("декабр")) {
            return Month.DECEMBER;
        }
        return null;
    }

    /** Результат разбора строки изменения для match с {@code ags.ra} / {@code ags.ra_change}. */
    record ParsedRcLine(int changeNumber, String reportNumber, LocalDate reportDate) {
    }
}
