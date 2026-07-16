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
     * Пакетное сообщение о пустых строках Excel (нет данных по колонкам маппинга).
     *
     * @param firstExcelRow первая строка диапазона (1-based)
     * @param lastExcelRow  последняя строка диапазона (1-based)
     * @param count         число пропущенных пустых строк
     * @return текст без префикса «⚠»
     */
    public static String formatEmptyRowsBatch(int firstExcelRow, int lastExcelRow, int count) {
        if (count <= 0) {
            return "пропущено пустых строк: 0";
        }
        if (count == 1) {
            return "Excel-строка " + firstExcelRow
                    + ": пропущено как пустая (нет данных по колонкам маппинга)";
        }
        return "Excel-строки " + firstExcelRow + "–" + lastExcelRow
                + " (" + count + " шт.): пропущено как пустые (нет данных по колонкам маппинга)";
    }

    /**
     * Сообщение о хвосте листа за нижней границей найденного диапазона.
     *
     * @param address         адрес диапазона (например {@code $P$2:$P$426})
     * @param lastExcelRow    нижняя строка диапазона (1-based)
     * @param beyondRowCount  число строк листа ниже диапазона
     */
    public static String formatBeyondDataRange(String address, int lastExcelRow, int beyondRowCount) {
        String addr = address == null || address.isBlank() ? "(адрес не указан)" : address.trim();
        return "За пределами диапазона " + addr
                + " (ниже строки " + lastExcelRow + ") не обрабатывалось "
                + beyondRowCount + " строк листа (хвост Excel / форматирование)";
    }

    /**
     * Причина OTHER type=5: непустая строка не whitelist/не аренда и без маркера в № ОА.
     * Подставляется в {@code ⚠ Excel-строка N: …} без собственного префикса строки.
     *
     * @param signDisplay отображаемый признак (уже trim; может быть {@code null})
     * @param raNumDisplay отображаемый № ОА (может быть {@code null})
     * @return текст причины
     */
    public static String formatType5OtherWithoutMarker(String signDisplay, String raNumDisplay) {
        String sign = blankToDash(signDisplay);
        String raNum = blankToDash(raNumDisplay);
        return "прочий номер/признак без маркера ОА (\\d{7}): Признак = «" + sign + "», № ОА = «" + raNum + "»";
    }

    /**
     * Итог: остальные OTHER не показаны поштучно (лимит топа).
     *
     * @param remaining сколько строк сверх уже залогированных
     */
    public static String formatType5OtherOverflow(int remaining) {
        if (remaining <= 0) {
            return "прочих строк без маркера № ОА: 0";
        }
        return "и ещё " + remaining + " прочих строк без маркера № ОА (см. топ выше / хвост)";
    }

    private static String blankToDash(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "—";
        }
        return value.trim();
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
