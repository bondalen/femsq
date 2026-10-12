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
 * <p>Полоса долга схлопывается в одну строку на {@code dbtKey}. Пустая ячейка внутри слитой
 * области берёт значение верхней ячейки. Пустая ячейка вне склейки поле не затирает.
 * Разные непустые тексты одной колонки не отклоняются: остаётся нижняя строка файла.
 */
public final class SudzRsltReturnImporter {

    private SudzRsltReturnImporter() {
    }

    /**
     * Читает строки с непустыми {@code *_new} и схлопывает полосу по {@code dbtKey}.
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
     * Одна запись на долг. Непустое значение нижних строк заменяет верхнее.
     *
     * @param physical строки листа сверху вниз
     * @return разбор
     */
    static SudzRsltReturnParse collapse(List<SudzRsltReturnRow> physical) {
        Map<Integer, Draft> byDebt = new LinkedHashMap<>();
        for (SudzRsltReturnRow row : physical) {
            Draft draft = byDebt.computeIfAbsent(row.dbtKey(), Draft::new);
            draft.parts++;
            draft.curator = mergeField(draft.curator, row.curatorNew(), draft);
            draft.mery = mergeField(draft.mery, row.meryNew(), draft);
            draft.cst = mergeField(draft.cst, row.cstCodeNew(), draft);
        }
        List<SudzRsltReturnRow> rows = new ArrayList<>();
        List<Integer> same = new ArrayList<>();
        List<Integer> different = new ArrayList<>();
        for (Draft draft : byDebt.values()) {
            rows.add(new SudzRsltReturnRow(draft.dbtKey, draft.curator, draft.mery, draft.cst));
            if (draft.parts > 1 && draft.different) {
                different.add(draft.dbtKey);
            } else if (draft.parts > 1) {
                same.add(draft.dbtKey);
            }
        }
        return new SudzRsltReturnParse(List.copyOf(rows), physical.size(), List.copyOf(same), List.copyOf(different));
    }

    private static String mergeField(String current, String incoming, Draft draft) {
        if (incoming == null) {
            return current;
        }
        if (current != null && !current.equals(incoming)) {
            draft.different = true;
        }
        return incoming;
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

    private static final class Draft {
        private final int dbtKey;
        private String curator;
        private String mery;
        private String cst;
        private int parts;
        private boolean different;

        private Draft(int dbtKey) {
            this.dbtKey = dbtKey;
        }
    }
}
