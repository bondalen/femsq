package com.femsq.web.audit.staging;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Форматирование причин пропуска строки Excel в режиме SUMMARY (задача 0049).
 */
public final class StagingRowSkipReasonFormatter {

    /** Максимум полей в сообщении; остальные — «и ещё N». */
    public static final int MAX_VISIBLE_REQUIRED_FIELDS = 3;

    private StagingRowSkipReasonFormatter() {
    }

    /**
     * Текст для пустых обязательных полей.
     *
     * @param missingColumns имена колонок БД в порядке обхода
     * @param excelHeaders   заголовки Excel по имени колонки
     * @return например «пропущено — пусто обязательное поле: col («Заголовок») и ещё 2»
     */
    public static String formatMissingRequiredFields(List<String> missingColumns, Map<String, String> excelHeaders) {
        if (missingColumns == null || missingColumns.isEmpty()) {
            return "пропущено — недостаточно обязательных данных";
        }
        List<String> labels = new ArrayList<>();
        for (String column : missingColumns) {
            labels.add(formatFieldLabel(column, excelHeaders));
        }
        int total = labels.size();
        int visible = Math.min(total, MAX_VISIBLE_REQUIRED_FIELDS);
        StringBuilder sb = new StringBuilder("пропущено — пусто обязательное поле: ");
        for (int i = 0; i < visible; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append(labels.get(i));
        }
        int remaining = total - visible;
        if (remaining > 0) {
            sb.append(" и ещё ").append(remaining);
        }
        return sb.toString();
    }

    /**
     * Подпись поля: {@code columnName («заголовок Excel»)} или только имя колонки.
     */
    public static String formatFieldLabel(String column, Map<String, String> excelHeaders) {
        if (column == null || column.isBlank()) {
            return "(неизвестная колонка)";
        }
        if (excelHeaders != null) {
            String header = excelHeaders.get(column);
            if (header != null && !header.isBlank()) {
                return column + " («" + header + "»)";
            }
        }
        return column;
    }
}
