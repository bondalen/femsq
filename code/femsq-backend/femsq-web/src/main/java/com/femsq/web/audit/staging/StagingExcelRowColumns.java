package com.femsq.web.audit.staging;

import java.util.Set;

/**
 * Синтетические колонки staging с номером строки листа Excel (1-based).
 * Заполняются в Stage 1 вне {@code ra_col_map} (аналог {@code *_exec_key}).
 */
public final class StagingExcelRowColumns {

    /** Известные имена колонок по типам staging-таблиц. */
    public static final Set<String> KNOWN = Set.of("rainRow", "ralprtRow", "ralprsRow", "oafptRow");

    private StagingExcelRowColumns() {
    }

    /**
     * Ищет колонку номера Excel-строки среди колонок таблицы БД.
     *
     * @param dbColumns имена колонок staging-таблицы (как в JDBC metadata)
     * @return фактическое имя колонки или {@code null}, если таблицы не содержат известного поля
     */
    public static String find(Set<String> dbColumns) {
        if (dbColumns == null || dbColumns.isEmpty()) {
            return null;
        }
        for (String known : KNOWN) {
            if (dbColumns.contains(known)) {
                return known;
            }
        }
        for (String column : dbColumns) {
            if (column == null) {
                continue;
            }
            for (String known : KNOWN) {
                if (known.equalsIgnoreCase(column)) {
                    return column;
                }
            }
        }
        return null;
    }

    /**
     * Признак синтетической колонки Excel-строки (не читать из ячейки листа).
     *
     * @param column         имя колонки INSERT
     * @param excelRowColumn найденная колонка таблицы или {@code null}
     * @return {@code true}, если значение задаётся кодом Stage 1
     */
    public static boolean isSynthetic(String column, String excelRowColumn) {
        if (column == null || excelRowColumn == null) {
            return false;
        }
        return excelRowColumn.equals(column) || excelRowColumn.equalsIgnoreCase(column);
    }
}
