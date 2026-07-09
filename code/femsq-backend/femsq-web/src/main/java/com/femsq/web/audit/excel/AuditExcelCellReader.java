package com.femsq.web.audit.excel;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoField;
import java.util.Locale;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.springframework.stereotype.Component;

/**
 * Унифицированное чтение значений ячеек Excel с преобразованием в нужные типы.
 * Поддерживает formula cells, русское форматирование чисел и типичные российские форматы дат.
 */
@Component
public class AuditExcelCellReader {

    private final DataFormatter dataFormatter = new DataFormatter();

    /** Двухзначный год в диапазоне 2000–2099 (как в Excel для «25» → 2025). */
    private static final DateTimeFormatter DD_MM_YY = new DateTimeFormatterBuilder()
            .appendPattern("dd.MM.")
            .appendValueReduced(ChronoField.YEAR, 2, 2, 2000)
            .toFormatter(Locale.ROOT);

    private static final DateTimeFormatter D_M_YY = new DateTimeFormatterBuilder()
            .appendPattern("d.M.")
            .appendValueReduced(ChronoField.YEAR, 2, 2, 2000)
            .toFormatter(Locale.ROOT);

    private static final DateTimeFormatter DD_MM_YYYY = DateTimeFormatter.ofPattern("dd.MM.yyyy", Locale.ROOT);
    private static final DateTimeFormatter D_M_YYYY = DateTimeFormatter.ofPattern("d.M.yyyy", Locale.ROOT);
    private static final DateTimeFormatter DD_M_YYYY = DateTimeFormatter.ofPattern("dd.M.yyyy", Locale.ROOT);

    /**
     * Возвращает строковое представление ячейки (trim) или null.
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
     * Возвращает LocalDate из date-ячейки или текстового формата; при нераспознанном непустом тексте — {@link CellReadResult#parseError()}.
     */
    public CellReadResult<LocalDate> readDateResult(Cell cell) {
        String asString = readString(cell);
        if (asString == null) {
            return CellReadResult.success(null, null);
        }
        LocalDate parsed = parseDateValue(cell, asString);
        if (parsed == null) {
            return CellReadResult.failure(asString,
                    "Failed to parse date from cell value: " + asString,
                    "дата");
        }
        return CellReadResult.success(parsed, asString);
    }

    /**
     * Возвращает LocalDate из date-ячейки или текстового формата, если возможно.
     */
    public LocalDate readDate(Cell cell) {
        CellReadResult<LocalDate> result = readDateResult(cell);
        return result.value();
    }

    /**
     * Возвращает целое число из ячейки; при ошибке формата — {@link CellReadResult#parseError()}, без исключения.
     */
    public CellReadResult<Integer> readIntResult(Cell cell) {
        String asString = readString(cell);
        if (asString == null) {
            return CellReadResult.success(null, null);
        }
        if ("-".equals(asString) || "—".equals(asString)) {
            return CellReadResult.success(null, asString);
        }
        try {
            if (cell != null && isNumericCell(cell) && !DateUtil.isCellDateFormatted(cell)) {
                return CellReadResult.success((int) Math.round(cell.getNumericCellValue()), asString);
            }
            return CellReadResult.success(Integer.valueOf(stripUnicodeSpaceSeparators(asString)), asString);
        } catch (NumberFormatException exception) {
            return CellReadResult.failure(asString,
                    "Failed to parse Integer from cell value: " + asString,
                    "целое число");
        }
    }

    /**
     * Возвращает целое число из ячейки или null; при ошибке формата бросает {@link AuditExcelException}.
     */
    public Integer readInt(Cell cell) {
        CellReadResult<Integer> result = readIntResult(cell);
        if (!result.ok()) {
            throw new AuditExcelException(result.parseError());
        }
        return result.value();
    }

    /**
     * Возвращает decimal-значение из ячейки; при ошибке формата — {@link CellReadResult#parseError()}, без исключения.
     */
    public CellReadResult<BigDecimal> readDecimalResult(Cell cell) {
        String asString = readString(cell);
        if (asString == null) {
            return CellReadResult.success(null, null);
        }
        if ("-".equals(asString) || "—".equals(asString)) {
            return CellReadResult.success(null, asString);
        }
        try {
            if (cell != null && isNumericCell(cell) && !DateUtil.isCellDateFormatted(cell)) {
                return CellReadResult.success(BigDecimal.valueOf(cell.getNumericCellValue()), asString);
            }
            String cleaned = normalizeDecimalString(stripUnicodeSpaceSeparators(asString));
            if (cleaned == null || cleaned.isEmpty() || "-".equals(cleaned)) {
                return CellReadResult.success(null, asString);
            }
            return CellReadResult.success(new BigDecimal(cleaned), asString);
        } catch (NumberFormatException exception) {
            return CellReadResult.failure(asString,
                    "Failed to parse Decimal from cell value: " + asString,
                    "число");
        }
    }

    /**
     * Возвращает decimal-значение из ячейки или null; при ошибке формата бросает {@link AuditExcelException}.
     */
    public BigDecimal readDecimal(Cell cell) {
        CellReadResult<BigDecimal> result = readDecimalResult(cell);
        if (!result.ok()) {
            throw new AuditExcelException(result.parseError());
        }
        return result.value();
    }

    /**
     * Нормализует строку числа с учётом русского форматирования:
     * пробел/неразрывный пробел как разделитель тысяч, запятая как десятичный разделитель.
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
                return s.replace(".", "").replace(",", ".");
            }
            return s.replace(",", "");
        }
        if (commaCount > 0) {
            if (commaCount == 1) {
                return s.replace(",", ".");
            }
            int lastComma = s.lastIndexOf(',');
            return s.substring(0, lastComma).replace(",", "") + "." + s.substring(lastComma + 1);
        }
        if (dotCount > 1) {
            int lastDot = s.lastIndexOf('.');
            return s.substring(0, lastDot).replace(".", "") + "." + s.substring(lastDot + 1);
        }
        return s;
    }

    private LocalDate parseDateValue(Cell cell, String asString) {
        if (cell != null && isNumericCell(cell) && DateUtil.isCellDateFormatted(cell)) {
            try {
                var localDateTime = cell.getLocalDateTimeCellValue();
                if (localDateTime != null) {
                    return localDateTime.toLocalDate();
                }
                return cell.getDateCellValue().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
            } catch (Exception ignored) {
                // fall through to text parsing
            }
        }
        return parseExcelLocalDate(asString);
    }

    /**
     * Разбор даты из текста ячейки: ISO, затем типичные российские форматы с точкой.
     */
    private static LocalDate parseExcelLocalDate(String asString) {
        try {
            return LocalDate.parse(asString);
        } catch (DateTimeParseException ignored) {
            // fall through
        }
        for (DateTimeFormatter formatter : new DateTimeFormatter[] {
                DD_MM_YYYY, D_M_YYYY, DD_M_YYYY, DD_MM_YY, D_M_YY, DateTimeFormatter.ISO_LOCAL_DATE
        }) {
            try {
                return LocalDate.parse(asString, formatter);
            } catch (DateTimeParseException ignored) {
                // try next
            }
        }
        return null;
    }

    /**
     * Убирает Unicode-разделители пробела ({@code Zs}), в т.ч. неразрывный и узкий неразрывный пробел.
     */
    private static String stripUnicodeSpaceSeparators(String value) {
        return value == null ? null : value.replaceAll("\\p{Zs}", "");
    }

    private boolean isNumericCell(Cell cell) {
        if (cell == null) {
            return false;
        }
        if (cell.getCellType() == CellType.NUMERIC) {
            return true;
        }
        return cell.getCellType() == CellType.FORMULA
                && cell.getCachedFormulaResultType() == CellType.NUMERIC;
    }
}
