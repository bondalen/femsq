package com.femsq.web.audit.excel;

import com.femsq.database.model.RaColMap;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.OptionalInt;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.springframework.stereotype.Component;

/**
 * Компонент поиска заголовочной строки и колонок в листе Excel.
 *
 * <p>Режимы матчинга:
 * <ul>
 *   <li>{@code "W"} — точное совпадение (trimmed, ignoreCase)</li>
 *   <li>{@code "P"} — частичное/содержит (trimmed contains, ignoreCase)</li>
 * </ul>
 */
@Component
public class AuditExcelColumnLocator {

    private final AuditExcelCellReader cellReader;

    public AuditExcelColumnLocator(AuditExcelCellReader cellReader) {
        this.cellReader = cellReader;
    }

    /**
     * Ищет строку-якорь на листе. Возвращает 0-based индекс строки или пустой {@link OptionalInt}.
     *
     * @param sheet       лист книги
     * @param anchor      текст якорного заголовка
     * @param anchorMatch режим матчинга ({@code "W"} или {@code "P"})
     */
    public OptionalInt findAnchorRow(Sheet sheet, String anchor, String anchorMatch) {
        if (sheet == null || anchor == null || anchor.isBlank()) {
            return OptionalInt.empty();
        }
        String anchorNorm = normalizeHeaderText(anchor);
        boolean partial = "P".equalsIgnoreCase(anchorMatch);

        for (int rowIdx = sheet.getFirstRowNum(); rowIdx <= sheet.getLastRowNum(); rowIdx++) {
            Row row = sheet.getRow(rowIdx);
            if (row == null) {
                continue;
            }
            for (int colIdx = row.getFirstCellNum(); colIdx < row.getLastCellNum(); colIdx++) {
                Cell cell = row.getCell(colIdx);
                String cellText = cellReader.readString(cell);
                if (cellText == null) {
                    continue;
                }
                String cellNorm = normalizeHeaderText(cellText);
                if (partial) {
                    if (cellNorm.contains(anchorNorm)) {
                        return OptionalInt.of(rowIdx);
                    }
                } else {
                    if (cellNorm.equals(anchorNorm)) {
                        return OptionalInt.of(rowIdx);
                    }
                }
            }
        }
        return OptionalInt.empty();
    }

    /**
     * Сопоставляет маппинги {@code mappings} с колонками заголовочной строки {@code headerRow}.
     * Возвращает карту: имя staging-колонки → 0-based индекс Excel-колонки.
     *
     * <p>Если для одной staging-колонки зарегистрировано несколько алиасов заголовка
     * ({@code rcmXlHdrPri}), используется первый найденный по возрастанию приоритета.
     */
    public Map<String, Integer> locateColumns(Row headerRow, List<RaColMap> mappings) {
        if (headerRow == null || mappings == null || mappings.isEmpty()) {
            return Map.of();
        }
        Map<Integer, String> cellTextCache = buildCellTextCache(headerRow);
        Map<String, List<RaColMap>> byColumn = groupByColumnSortedByPriority(mappings);

        Map<String, Integer> result = new LinkedHashMap<>();
        for (Map.Entry<String, List<RaColMap>> entry : byColumn.entrySet()) {
            String stagingCol = entry.getKey();
            for (RaColMap mapping : entry.getValue()) {
                String headerPattern = mapping.rcmXlHdr();
                if (headerPattern == null || headerPattern.isBlank()) {
                    continue;
                }
                String patternNorm = normalizeHeaderText(headerPattern);
                boolean partial = "P".equalsIgnoreCase(mapping.rcmXlMatch());
                OptionalInt found = findColumnByHeader(cellTextCache, patternNorm, partial);
                if (found.isPresent()) {
                    result.put(stagingCol, found.getAsInt());
                    break;
                }
            }
        }
        return result;
    }

    private Map<Integer, String> buildCellTextCache(Row headerRow) {
        Map<Integer, String> cache = new HashMap<>();
        for (int i = headerRow.getFirstCellNum(); i < headerRow.getLastCellNum(); i++) {
            Cell cell = headerRow.getCell(i);
            String text = cellReader.readString(cell);
            if (text != null) {
                cache.put(i, normalizeHeaderText(text));
            }
        }
        return cache;
    }

    private Map<String, List<RaColMap>> groupByColumnSortedByPriority(List<RaColMap> mappings) {
        Map<String, List<RaColMap>> byColumn = new LinkedHashMap<>();
        List<RaColMap> sorted = new ArrayList<>(mappings);
        sorted.sort(Comparator
                .comparing(RaColMap::rcmTblColOrd)
                .thenComparing(m -> m.rcmXlHdrPri() == null ? Integer.MAX_VALUE : m.rcmXlHdrPri())
                .thenComparing(m -> m.rcmKey() == null ? Integer.MAX_VALUE : m.rcmKey()));
        for (RaColMap m : sorted) {
            byColumn.computeIfAbsent(m.rcmTblCol(), k -> new ArrayList<>()).add(m);
        }
        return byColumn;
    }

    private OptionalInt findColumnByHeader(Map<Integer, String> cellTextCache, String patternNorm, boolean partial) {
        for (Map.Entry<Integer, String> entry : cellTextCache.entrySet()) {
            String cellNorm = entry.getValue();
            if (partial) {
                if (cellNorm.contains(patternNorm)) {
                    return OptionalInt.of(entry.getKey());
                }
            } else {
                if (cellNorm.equals(patternNorm)) {
                    return OptionalInt.of(entry.getKey());
                }
            }
        }
        return OptionalInt.empty();
    }

    /**
     * Нормализация текста заголовка: нижний регистр, замена переносов строк пробелом, сжатие пробелов.
     */
    private String normalizeHeaderText(String text) {
        if (text == null) {
            return "";
        }
        return text
                .replace("\r\n", " ")
                .replace("\n", " ")
                .replace("\r", " ")
                .replaceAll("\\s{2,}", " ")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
