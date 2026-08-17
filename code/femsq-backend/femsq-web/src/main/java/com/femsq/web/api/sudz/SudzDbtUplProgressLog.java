package com.femsq.web.api.sudz;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * HTML-лог воронки загрузки свода: хронология сверху вниз, блоки {@code <details>} со свёрткой +/−.
 * Использовать в каждом шаге воронки (excelToTbl и далее).
 */
public final class SudzDbtUplProgressLog {

    private final StringBuilder html = new StringBuilder();
    private int openBlocks;

    /**
     * Строка лога (абзац).
     *
     * @param innerHtml содержимое без обёртки {@code p}
     * @return this
     */
    public SudzDbtUplProgressLog line(String innerHtml) {
        html.append("<p>").append(innerHtml == null ? "" : innerHtml).append("</p>\n");
        return this;
    }

    /**
     * Вставляет уже собранный HTML-фрагмент (вложенный лог листа и т.п.).
     *
     * @param fragment HTML
     * @return this
     */
    public SudzDbtUplProgressLog raw(String fragment) {
        if (fragment != null && !fragment.isEmpty()) {
            html.append(fragment);
        }
        return this;
    }

    /**
     * Открывает сворачиваемый блок.
     *
     * @param titleHtml заголовок (HTML)
     * @param expanded {@code true} — развёрнут
     * @return this
     */
    public SudzDbtUplProgressLog open(String titleHtml, boolean expanded) {
        html.append("<details class=\"sudz-funnel-log-block\"");
        if (expanded) {
            html.append(" open");
        }
        html.append("><summary><span class=\"sudz-funnel-log-pm\" aria-hidden=\"true\"></span> ")
                .append(titleHtml == null ? "" : titleHtml)
                .append("</summary><div class=\"sudz-funnel-log-body\">\n");
        openBlocks++;
        return this;
    }

    /**
     * Закрывает последний {@link #open}.
     *
     * @return this
     */
    public SudzDbtUplProgressLog close() {
        if (openBlocks <= 0) {
            throw new IllegalStateException("close() без open()");
        }
        html.append("</div></details>\n");
        openBlocks--;
        return this;
    }

    /**
     * Текущая метка времени для строк лога.
     *
     * @return {@code yyyy-MM-dd HH:mm:ss}
     */
    public static String now() {
        return LocalDateTime.now().withNano(0).toString().replace('T', ' ');
    }

    /**
     * Экранирование текста в HTML.
     *
     * @param raw исходник
     * @return безопасная строка
     */
    public static String escape(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    /**
     * Собранный HTML. Все блоки должны быть закрыты.
     *
     * @return фрагмент
     */
    public String toHtml() {
        if (openBlocks != 0) {
            throw new IllegalStateException("Не закрыты блоки details: " + openBlocks);
        }
        return html.toString();
    }

    /**
     * Проверяет, что лог не пуст.
     *
     * @return true если есть содержимое
     */
    public boolean isEmpty() {
        return html.isEmpty();
    }

    @Override
    public String toString() {
        return toHtml();
    }

    /**
     * Гарантирует ненулевой лог (для отладки).
     *
     * @param other другой лог
     * @return this
     */
    public SudzDbtUplProgressLog merge(SudzDbtUplProgressLog other) {
        Objects.requireNonNull(other, "other");
        return raw(other.toHtml());
    }
}
