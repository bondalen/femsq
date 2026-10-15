package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltReturnRow;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FormulaEvaluator;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Разбор Excel возврата Rslt: колонки {@code dbtKey} + {@code *_new} (строка 3 — техн. имена).
 *
 * <p>Полоса долга сохраняет строки с ординалом для стыковки с {@code DbtValue} крайней upl.
 * Пустая ячейка внутри слитой области берёт значение верхней ячейки. Пустая ячейка вне
 * склейки поле не затирает. Разные непустые тексты одной колонки остаются на разных строках полосы.
 */
public final class SudzRsltReturnImporter {

    private SudzRsltReturnImporter() {
    }

    /**
     * Читает строки с непустыми {@code *_new}; полоса одного {@code dbtKey} даёт несколько
     * записей с {@code bandOrdinal}.
     *
     * @param input поток xlsx
     * @return разбор для записи и протокола
     * @throws IOException ошибка чтения
     */
    public static SudzRsltReturnParse parse(InputStream input) throws IOException {
        DataFormatter formatter = new DataFormatter();
        try (Workbook workbook = new XSSFWorkbook(input)) {
            Sheet sheet = workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
            if (sheet == null) {
                throw new IllegalArgumentException("В книге нет листов");
            }
            Row techRow = sheet.getRow(2);
            if (techRow == null) {
                throw new IllegalArgumentException("Нет строки техн. имён (row3)");
            }
            Map<String, Integer> cols = new HashMap<>();
            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
            for (Cell cell : techRow) {
                String name = formatter.formatCellValue(cell);
                if (name != null && !name.isBlank()) {
                    cols.put(name.trim(), cell.getColumnIndex());
                }
            }
            Integer dbtCol = cols.get("dbtKey");
            Integer curCol = cols.get("cur_new");
            Integer meryCol = cols.get("mery_new");
            Integer cstCol = cols.get("cstAgPn_new");
            if (dbtCol == null) {
                throw new IllegalArgumentException("Не найдена колонка dbtKey");
            }
            if (curCol == null && meryCol == null && cstCol == null) {
                throw new IllegalArgumentException("Не найдены колонки cur_new / mery_new / cstAgPn_new");
            }

            List<SudzRsltReturnRow> physical = new ArrayList<>();
            for (int r = 3; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) {
                    continue;
                }
                String dbtRaw = cellText(sheet, formatter, evaluator, r, dbtCol);
                if (dbtRaw == null || dbtRaw.isBlank()) {
                    continue;
                }
                int dbtKey;
                try {
                    dbtKey = (int) Double.parseDouble(dbtRaw.replace(',', '.').trim());
                } catch (NumberFormatException exception) {
                    continue;
                }
                String curator = curCol == null ? null : blankToNull(cellText(sheet, formatter, evaluator, r, curCol));
                String mery = meryCol == null ? null : blankToNull(cellText(sheet, formatter, evaluator, r, meryCol));
                String cst = cstCol == null ? null : blankToNull(cellText(sheet, formatter, evaluator, r, cstCol));
                if (curator == null && mery == null && cst == null) {
                    continue;
                }
                physical.add(new SudzRsltReturnRow(dbtKey, curator, mery, cst));
            }
            return collapse(physical);
        }
    }

    /**
     * Сохраняет строки полосы с ординалом; отмечает долги с одинаковым / разным текстом.
     *
     * @param physical строки листа сверху вниз
     * @return разбор
     */
    static SudzRsltReturnParse collapse(List<SudzRsltReturnRow> physical) {
        Map<Integer, List<SudzRsltReturnRow>> byDebt = new LinkedHashMap<>();
        for (SudzRsltReturnRow row : physical) {
            byDebt.computeIfAbsent(row.dbtKey(), key -> new ArrayList<>()).add(row);
        }
        List<SudzRsltReturnRow> rows = new ArrayList<>();
        List<Integer> same = new ArrayList<>();
        List<Integer> different = new ArrayList<>();
        for (Map.Entry<Integer, List<SudzRsltReturnRow>> entry : byDebt.entrySet()) {
            int dbtKey = entry.getKey();
            List<SudzRsltReturnRow> band = entry.getValue();
            boolean differs = bandDiffers(band);
            if (band.size() > 1) {
                if (differs) {
                    different.add(dbtKey);
                } else {
                    same.add(dbtKey);
                }
            }
            for (int i = 0; i < band.size(); i++) {
                SudzRsltReturnRow part = band.get(i);
                rows.add(new SudzRsltReturnRow(
                        dbtKey,
                        part.curatorNew(),
                        part.meryNew(),
                        part.cstCodeNew(),
                        i));
            }
        }
        return new SudzRsltReturnParse(List.copyOf(rows), physical.size(), List.copyOf(same), List.copyOf(different));
    }

    private static boolean bandDiffers(List<SudzRsltReturnRow> band) {
        String curator = null;
        String mery = null;
        String cst = null;
        boolean seenCurator = false;
        boolean seenMery = false;
        boolean seenCst = false;
        for (SudzRsltReturnRow row : band) {
            if (row.curatorNew() != null) {
                if (seenCurator && !row.curatorNew().equals(curator)) {
                    return true;
                }
                curator = row.curatorNew();
                seenCurator = true;
            }
            if (row.meryNew() != null) {
                if (seenMery && !row.meryNew().equals(mery)) {
                    return true;
                }
                mery = row.meryNew();
                seenMery = true;
            }
            if (row.cstCodeNew() != null) {
                if (seenCst && !row.cstCodeNew().equals(cst)) {
                    return true;
                }
                cst = row.cstCodeNew();
                seenCst = true;
            }
        }
        return false;
    }

    /**
     * Текст ячейки. Формулы читаются по вычисленному значению.
     * Пустая ячейка слитой области получает текст верхней ячейки.
     *
     * @param sheet лист
     * @param formatter форматтер POI
     * @param evaluator вычислитель формул книги
     * @param rowIndex 0-based строка
     * @param col индекс колонки
     * @return текст, пустая строка если значения нет
     */
    private static String cellText(
            Sheet sheet,
            DataFormatter formatter,
            FormulaEvaluator evaluator,
            int rowIndex,
            int col
    ) {
        Row row = sheet.getRow(rowIndex);
        String direct = row == null ? "" : format(formatter, evaluator, row.getCell(col));
        if (!direct.isBlank()) {
            return direct;
        }
        for (CellRangeAddress region : sheet.getMergedRegions()) {
            if (!region.isInRange(rowIndex, col)) {
                continue;
            }
            if (region.getFirstRow() == rowIndex && region.getFirstColumn() == col) {
                return direct;
            }
            Row originRow = sheet.getRow(region.getFirstRow());
            if (originRow == null) {
                return "";
            }
            return format(formatter, evaluator, originRow.getCell(region.getFirstColumn()));
        }
        return direct;
    }

    private static String format(DataFormatter formatter, FormulaEvaluator evaluator, Cell cell) {
        if (cell == null) {
            return "";
        }
        return formatter.formatCellValue(cell, evaluator);
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
