package com.femsq.database.util;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Нормализация имён разделов для поиска Excel↔{@code stIpgNm} (контракт O1 §5.2).
 * Сырой текст в БД не меняет.
 */
public final class StructureNameNormalizer {

    private static final Pattern SECTION_PREFIX = Pattern.compile("^\\d+(?:\\.\\d+)*\\.?\\s+");
    private static final Pattern MULTISPACE = Pattern.compile("\\s+");

    private StructureNameNormalizer() {
    }

    /**
     * Нормализует строку для сравнения имён/путей.
     *
     * @param raw исходный текст (может быть с нумерацией раздела)
     * @return нормализованная строка; пустая если raw null/blank
     */
    public static String normalize(String raw) {
        if (raw == null || raw.isBlank()) {
            return "";
        }
        String value = raw
                .replace('\u00a0', ' ')
                .replace('\u202f', ' ')
                .replace('«', '"')
                .replace('»', '"')
                .replace('"', '"')
                .replace('"', '"')
                .trim();
        value = SECTION_PREFIX.matcher(value).replaceFirst("");
        value = MULTISPACE.matcher(value).replaceAll(" ").trim();
        value = value.toLowerCase(Locale.ROOT);
        // варианты пунктуации в эталоне / Excel
        value = value.replace("м.р.", "м/р").replace("м. р.", "м/р");
        value = value.replace("о. ", "о.");
        return value;
    }

    /**
     * Заголовок раздела без префикса нумерации (сырой, без lower-case).
     */
    public static String stripSectionNumber(String raw) {
        if (raw == null || raw.isBlank()) {
            return "";
        }
        String value = raw
                .replace('\u00a0', ' ')
                .replace('\u202f', ' ')
                .trim();
        value = SECTION_PREFIX.matcher(value).replaceFirst("");
        return MULTISPACE.matcher(value).replaceAll(" ").trim();
    }
}
