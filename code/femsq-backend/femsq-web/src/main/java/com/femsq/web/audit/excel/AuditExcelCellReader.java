package com.femsq.web.audit.excel;

import java.math.BigDecimal;
import java.time.LocalDate;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.springframework.stereotype.Component;

/**
 * Утилита чтения значений из ячеек Apache POI.
 * Обеспечивает безопасное чтение с нормализацией null/blank.
 */
@Component
public class AuditExcelCellReader {

    private final DataFormatter dataFormatter = new DataFormatter();

    /**
     * Читает ячейку как строку. Возвращает trimmed-значение или {@code null} для пустых ячеек.
     */
    public String readString(Cell cell) {
        if (cell == null) {
            return null;
        }
        CellType effectiveType = cell.getCellType() == CellType.FORMULA
                ? cell.getCachedFormulaResultType()
                : cell.getCellType();
        String raw;
        switch (effectiveType) {
            case BLANK -> {
                return null;
            }
            case BOOLEAN -> raw = Boolean.toString(cell.getBooleanCellValue());
            case NUMERIC -> raw = dataFormatter.formatCellValue(cell);
            case STRING -> raw = cell.getStringCellValue();
            default -> raw = dataFormatter.formatCellValue(cell);
        }
        if (raw == null) {
            return null;
        }
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /**
     * Читает ячейку как дату ({@link LocalDate}). Возвращает {@code null} если ячейка пуста или не является датой.
     */
    public LocalDate readDate(Cell cell) {
        if (cell == null) {
            return null;
        }
        CellType effectiveType = cell.getCellType() == CellType.FORMULA
                ? cell.getCachedFormulaResultType()
                : cell.getCellType();
        if (effectiveType == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            try {
                var ldt = cell.getLocalDateTimeCellValue();
                return ldt == null ? null : ldt.toLocalDate();
            } catch (Exception e) {
                return null;
            }
        }
        if (effectiveType == CellType.STRING) {
            String raw = cell.getStringCellValue();
            if (raw == null || raw.isBlank()) {
                return null;
            }
            return tryParseDate(raw.trim());
        }
        return null;
    }

    /**
     * Читает ячейку как целое число. Возвращает {@code null} если ячейка пуста или не является числом.
     */
    public Integer readInt(Cell cell) {
        if (cell == null) {
            return null;
        }
        CellType effectiveType = cell.getCellType() == CellType.FORMULA
                ? cell.getCachedFormulaResultType()
                : cell.getCellType();
        if (effectiveType == CellType.NUMERIC) {
            return (int) cell.getNumericCellValue();
        }
        if (effectiveType == CellType.STRING) {
            String raw = cell.getStringCellValue();
            if (raw == null || raw.isBlank()) {
                return null;
            }
            try {
                return Integer.parseInt(raw.trim());
            } catch (NumberFormatException e) {
                try {
                    return (int) Double.parseDouble(raw.trim());
                } catch (NumberFormatException ex) {
                    throw new AuditExcelException("Failed to parse Integer from cell value: " + raw, ex);
                }
            }
        }
        return null;
    }

    /**
     * Читает ячейку как BigDecimal. Возвращает {@code null} если ячейка пуста или не является числом.
     */
    public BigDecimal readDecimal(Cell cell) {
        if (cell == null) {
            return null;
        }
        CellType effectiveType = cell.getCellType() == CellType.FORMULA
                ? cell.getCachedFormulaResultType()
                : cell.getCellType();
        if (effectiveType == CellType.NUMERIC) {
            return BigDecimal.valueOf(cell.getNumericCellValue());
        }
        if (effectiveType == CellType.STRING) {
            String raw = cell.getStringCellValue();
            if (raw == null || raw.isBlank()) {
                return null;
            }
            String cleaned = normalizeDecimalString(raw.trim());
            if (cleaned == null || cleaned.equals("-") || cleaned.isEmpty()) {
                return null;
            }
            try {
                return new BigDecimal(cleaned);
            } catch (NumberFormatException e) {
                throw new AuditExcelException("Failed to parse Decimal from cell value: " + raw, e);
            }
        }
        return null;
    }

    /**
     * Нормализует строку числа с учётом русского форматирования:
     * пробел/неразрывный пробел как разделитель тысяч, запятая как десятичный разделитель.
     * Примеры: "130 092,19" → "130092.19", "130,092,19" → "130092.19", "1.234.567,89" → "1234567.89".
     */
    private String normalizeDecimalString(String value) {
        if (value == null) {
            return null;
        }
        String s = value
                .replace("\u00A0", "")
                .replace("\u202F", "")
                .replace(" ", "");
        if (s.isEmpty() || s.equals("-")) {
            return s;
        }
        long commaCount = s.chars().filter(c -> c == ',').count();
        long dotCount = s.chars().filter(c -> c == '.').count();
        if (commaCount == 0 && dotCount == 0) {
            return s;
        }
        if (commaCount > 0 && dotCount > 0) {
            int lastComma = s.lastIndexOf(',');
            int lastDot = s.lastIndexOf('.');
            if (lastComma > lastDot) {
                // comma is decimal separator, dots are thousands
                return s.replace(".", "").replace(",", ".");
            } else {
                // dot is decimal separator, commas are thousands
                return s.replace(",", "");
            }
        }
        if (commaCount > 0) {
            if (commaCount == 1) {
                return s.replace(",", ".");
            }
            // Multiple commas: all but last are thousands separators
            int lastComma = s.lastIndexOf(',');
            return s.substring(0, lastComma).replace(",", "") + "." + s.substring(lastComma + 1);
        }
        if (dotCount > 1) {
            // Multiple dots: all but last are thousands separators
            int lastDot = s.lastIndexOf('.');
            return s.substring(0, lastDot).replace(".", "") + "." + s.substring(lastDot + 1);
        }
        return s;
    }

    private LocalDate tryParseDate(String raw) {
        java.time.format.DateTimeFormatter[] formatters = {
                java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy"),
                java.time.format.DateTimeFormatter.ofPattern("d.MM.yyyy"),
                java.time.format.DateTimeFormatter.ofPattern("dd.M.yyyy"),
                java.time.format.DateTimeFormatter.ISO_LOCAL_DATE
        };
        for (var fmt : formatters) {
            try {
                return LocalDate.parse(raw, fmt);
            } catch (Exception ignored) {
            }
        }
        return null;
    }
}
