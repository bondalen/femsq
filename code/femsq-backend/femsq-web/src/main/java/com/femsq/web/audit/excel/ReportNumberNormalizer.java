package com.femsq.web.audit.excel;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Нормализация строкового номера отчёта/ОА к виду, близкому к VBA {@code CStr} для целых.
 * <p>
 * Apache POI {@code DataFormatter} для numeric-ячейки {@code 480} часто даёт {@code "480,00"} /
 * {@code "480.00"} (локаль), тогда как Access VBA и уже сохранённый домен обычно хранят {@code "480"}.
 * Без нормализации reconcile даёт ложный orphan DELETE + NEW INSERT.
 * </p>
 * Не трогает составные номера ({@code 480/310326}, {@code 1011/300626 кор} и т.п.).
 */
public final class ReportNumberNormalizer {

    /** Целое с нулевой дробной частью: {@code 480,00} / {@code 480.00}. */
    private static final Pattern WHOLE_WITH_ZERO_FRACTION = Pattern.compile("^(\\d+)[.,]0+$");

    private ReportNumberNormalizer() {
    }

    /**
     * Приводит номер к канонической строке для ключа сверки и записи в staging/домен.
     *
     * @param raw исходная строка (может быть {@code null})
     * @return trim; для {@code N,00}/{@code N.00} → {@code N}; иначе исходная (после trim); пусто → {@code null}
     */
    public static String normalize(String raw) {
        if (raw == null) {
            return null;
        }
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        Matcher matcher = WHOLE_WITH_ZERO_FRACTION.matcher(trimmed);
        if (matcher.matches()) {
            return matcher.group(1);
        }
        return trimmed;
    }
}
