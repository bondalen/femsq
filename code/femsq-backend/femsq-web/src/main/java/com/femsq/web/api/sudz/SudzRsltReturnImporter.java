package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltReturnRow;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Разбор Excel возврата Rslt: колонки {@code dbtKey} + {@code *_new} (строка 3 — техн. имена).
 */
public final class SudzRsltReturnImporter {

    private SudzRsltReturnImporter() {
    }

    /**
     * Читает строки с непустыми {@code *_new}.
     *
     * @param input поток xlsx
     * @return строки импорта
     * @throws IOException ошибка чтения
     */
    public static List<SudzRsltReturnRow> parse(InputStream input) throws IOException {
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

            List<SudzRsltReturnRow> rows = new ArrayList<>();
            for (int r = 3; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) {
                    continue;
                }
                String dbtRaw = formatter.formatCellValue(row.getCell(dbtCol));
                if (dbtRaw == null || dbtRaw.isBlank()) {
                    continue;
                }
                int dbtKey;
                try {
                    dbtKey = (int) Double.parseDouble(dbtRaw.replace(',', '.').trim());
                } catch (NumberFormatException exception) {
                    continue;
                }
                String curator = curCol == null ? null : blankToNull(formatter.formatCellValue(row.getCell(curCol)));
                String mery = meryCol == null ? null : blankToNull(formatter.formatCellValue(row.getCell(meryCol)));
                String cst = cstCol == null ? null : blankToNull(formatter.formatCellValue(row.getCell(cstCol)));
                if (curator == null && mery == null && cst == null) {
                    continue;
                }
                rows.add(new SudzRsltReturnRow(dbtKey, curator, mery, cst));
            }
            return List.copyOf(rows);
        }
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
