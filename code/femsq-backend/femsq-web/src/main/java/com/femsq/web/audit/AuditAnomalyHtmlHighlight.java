package com.femsq.web.audit;

/**
 * HTML-подсветка в логе ревизии (задачи 0051 / U10+).
 * <ul>
 *   <li>{@code femsq-anomaly-val} — некорректное значение (бордовый);</li>
 *   <li>{@code femsq-anomaly-ref} — номер Excel-строки / номер отчёта (фиолетовый).</li>
 * </ul>
 */
public final class AuditAnomalyHtmlHighlight {

    private static final String OPEN_VAL = "<span class=\"femsq-anomaly-val\">";
    private static final String OPEN_REF = "<span class=\"femsq-anomaly-ref\">";
    private static final String CLOSE = "</span>";

    private AuditAnomalyHtmlHighlight() {
    }

    /**
     * Некорректное значение (стройка, отправитель, имя поля и т.п.).
     */
    public static String value(String rawPlain) {
        return OPEN_VAL + escape(rawPlain == null ? "" : rawPlain) + CLOSE;
    }

    /**
     * Ссылка-ориентир: номер Excel-строки или номер отчёта.
     */
    public static String ref(String rawPlain) {
        return OPEN_REF + escape(rawPlain == null ? "" : rawPlain) + CLOSE;
    }

    /**
     * Ссылка-ориентир для числового номера строки.
     */
    public static String ref(int excelRow) {
        return OPEN_REF + excelRow + CLOSE;
    }

    /**
     * Значение в кавычках-ёлочках с бордовой подсветкой.
     */
    public static String guillemet(String rawPlain) {
        return "«" + value(rawPlain) + "»";
    }

    /**
     * Номер отчёта в кавычках-ёлочках с фиолетовой подсветкой.
     */
    public static String guillemetRef(String rawPlain) {
        return "«" + ref(rawPlain) + "»";
    }

    /**
     * Экранирует plain-текст и подсвечивает содержимое каждой пары «…» бордовым.
     */
    public static String highlightGuillemetValues(String plain) {
        if (plain == null || plain.isEmpty()) {
            return "";
        }
        StringBuilder out = new StringBuilder(plain.length() + 32);
        int i = 0;
        while (i < plain.length()) {
            int open = plain.indexOf('«', i);
            if (open < 0) {
                out.append(escape(plain.substring(i)));
                break;
            }
            out.append(escape(plain.substring(i, open)));
            int close = plain.indexOf('»', open + 1);
            if (close < 0) {
                out.append(escape(plain.substring(open)));
                break;
            }
            out.append(guillemet(plain.substring(open + 1, close)));
            i = close + 1;
        }
        return out.toString();
    }

    /**
     * Префикс «Excel-строка N[, лист «…»]: » с подсвеченным N.
     */
    public static String excelRowPrefixHtml(Integer excelRow, String sheetName) {
        if (excelRow != null && excelRow > 0) {
            StringBuilder sb = new StringBuilder("Excel-строка ");
            sb.append(ref(excelRow));
            if (sheetName != null && !sheetName.isBlank()) {
                sb.append(", лист «").append(escape(sheetName.trim())).append("»");
            }
            sb.append(": ");
            return sb.toString();
        }
        return "строка промежуточной таблицы (номер Excel неизвестен): ";
    }

    private static String escape(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
