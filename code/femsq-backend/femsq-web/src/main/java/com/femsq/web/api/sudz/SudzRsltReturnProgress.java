package com.femsq.web.api.sudz;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Протокол одного прогона «Rslt повтор · Загрузить». Заменяет прежний текст {@code yr_Progress}.
 */
public final class SudzRsltReturnProgress {

    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private SudzRsltReturnProgress() {
    }

    /**
     * Текст протокола успешной записи.
     *
     * @param fileName имя файла
     * @param yr ключ года
     * @param parse разбор листа
     * @param imported сколько долгов записано
     * @param now системное время прогона
     * @return многострочный текст
     */
    public static String success(
            String fileName,
            int yr,
            SudzRsltReturnParse parse,
            int imported,
            LocalDateTime now
    ) {
        return render(fileName, yr, parse, imported, null, now);
    }

    /**
     * Текст протокола отката: в группу ничего не записано.
     *
     * @param fileName имя файла
     * @param yr ключ года
     * @param parse разбор листа или {@code null}, если лист не прочитан
     * @param reason причина для оператора
     * @param now системное время прогона
     * @return многострочный текст
     */
    public static String failure(
            String fileName,
            int yr,
            SudzRsltReturnParse parse,
            String reason,
            LocalDateTime now
    ) {
        return render(fileName, yr, parse, 0, reason, now);
    }

    private static String render(
            String fileName,
            int yr,
            SudzRsltReturnParse parse,
            int imported,
            String failureReason,
            LocalDateTime now
    ) {
        StringBuilder text = new StringBuilder();
        text.append("Rslt повтор · Загрузить\n");
        text.append(now.format(TS)).append('\n');
        text.append("Файл: ").append(fileName == null || fileName.isBlank() ? "return.xlsx" : fileName).append('\n');
        text.append("Год: ").append(yr).append('\n');
        if (parse == null) {
            text.append("Прочитано строк с заполненными *_new: нет\n");
        } else {
            text.append("Прочитано строк с заполненными *_new: ").append(parse.sourceRows()).append('\n');
            text.append("Разных долгов: ").append(parse.rows().size()).append('\n');
            appendKeys(text, "Полоса, один и тот же текст: ", parse.sameTextKeys());
            appendKeys(text, "Полоса, тексты разошлись, записана нижняя строка: ", parse.differentTextKeys());
        }
        if (failureReason == null) {
            text.append("Итог: записано ").append(imported);
        } else {
            text.append("Итог: записано 0, откат\n");
            text.append("Причина: ").append(failureReason.trim());
        }
        return text.toString();
    }

    private static void appendKeys(StringBuilder text, String label, List<Integer> keys) {
        if (keys == null || keys.isEmpty()) {
            return;
        }
        text.append(label);
        for (int i = 0; i < keys.size(); i++) {
            if (i > 0) {
                text.append(", ");
            }
            text.append(keys.get(i));
        }
        text.append('\n');
    }
}
