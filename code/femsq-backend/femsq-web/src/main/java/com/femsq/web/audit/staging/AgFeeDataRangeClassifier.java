package com.femsq.web.audit.staging;

import com.femsq.web.audit.excel.AuditExcelCellReader;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;

/**
 * Критерий «значимой» строки листа type=6 (AgFee) для нижней границы диапазона Stage 1.
 *
 * <p>Файлы «Свод инф-ции по Актам» часто имеют UsedRange до ~655xx и строку-мусор внизу
 * (счётчик/итог в колонках «№ Акта»/«Дата» без кода стройки). Одна непустая ячейка «№ Акта»
 * недостаточна — иначе диапазон захватывает тысячи пустых строк и сыпет WARN.
 */
public final class AgFeeDataRangeClassifier {

    private AgFeeDataRangeClassifier() {
    }

    /**
     * Значимость по уже прочитанным значениям (для unit-тестов и Stage 1).
     *
     * @param actNum           № Акта (trim), может быть null
     * @param cstCode          код стройки, может быть null
     * @param excelDatePresent {@code true}, если в колонке даты — ячейка даты Excel
     * @return {@code true}, если строка должна входить в диапазон данных
     */
    public static boolean isSignificantValues(String actNum, String cstCode, boolean excelDatePresent) {
        if (actNum == null || actNum.isBlank()) {
            return false;
        }
        if (cstCode != null && !cstCode.isBlank()) {
            return true;
        }
        return excelDatePresent;
    }

    /**
     * Строка значима, если есть № Акта и либо код стройки, либо ячейка даты в формате даты Excel
     * (не «голое» число вроде 665).
     *
     * @param row        строка листа (может быть {@code null})
     * @param actNameCol индекс колонки {@code oafptOafName} (0-based), обязателен
     * @param cstCol     индекс {@code oafptPnCstAgPn} или {@code null}
     * @param dateCol    индекс {@code oafptOafDate} или {@code null}
     * @param cellReader читатель ячеек
     * @return {@code true}, если строка должна входить в диапазон данных
     */
    public static boolean isSignificantRow(
            Row row,
            Integer actNameCol,
            Integer cstCol,
            Integer dateCol,
            AuditExcelCellReader cellReader
    ) {
        if (row == null || cellReader == null || actNameCol == null || actNameCol < 0) {
            return false;
        }
        String act = cellReader.readString(row.getCell(actNameCol));
        String cst = null;
        if (cstCol != null && cstCol >= 0) {
            cst = cellReader.readString(row.getCell(cstCol));
        }
        boolean excelDate = dateCol != null && dateCol >= 0 && isExcelDateCell(row.getCell(dateCol));
        return isSignificantValues(act, cst, excelDate);
    }

    /**
     * Ячейка — дата Excel (numeric + date format), а не произвольное число.
     */
    static boolean isExcelDateCell(Cell cell) {
        if (cell == null) {
            return false;
        }
        CellType type = cell.getCellType() == CellType.FORMULA
                ? cell.getCachedFormulaResultType()
                : cell.getCellType();
        if (type != CellType.NUMERIC) {
            return false;
        }
        try {
            return DateUtil.isCellDateFormatted(cell);
        } catch (Exception ignored) {
            return false;
        }
    }
}
