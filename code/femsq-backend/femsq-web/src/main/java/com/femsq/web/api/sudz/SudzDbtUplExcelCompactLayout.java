package com.femsq.web.api.sudz;

import com.femsq.web.audit.excel.AuditExcelCellReader;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;

/**
 * Компактная раскладка выгрузки БУиРГ без строки заголовков (QII 606012 и аналоги).
 * <p>
 * Колонки (0-based): A=вид, B=счёт ГК, C=№ контрагента, D=контрагент, E=договор, F=СФ,
 * G=дата образования, H=срок погашения, I=сумма, J=просрочка, K=doc ГК, L=ссылка.
 * ИНН и дата договора отсутствуют.
 */
final class SudzDbtUplExcelCompactLayout {

    static final int COL_ORG_NUM = 2;
    static final int COL_ORG_NAME = 3;
    static final int COL_CN = 4;
    static final int COL_INV = 5;
    static final int COL_FORM = 6;
    static final int COL_MAT = 7;
    static final int COL_DEBT = 8;
    static final int COL_OVERDUE = 9;
    static final int COL_DOC = 10;
    static final int COL_LINK = 11;

    private static final String DEBT_KIND = "D";

    private SudzDbtUplExcelCompactLayout() {
    }

    /**
     * Проверяет сигнатуру компактного листа по первой строке данных.
     *
     * @param sheet лист Excel
     * @param sheetName имя листа (должно совпасть с col B)
     * @param reader чтение ячеек
     * @return true, если раскладка узнаётся как compact no-header
     */
    static boolean matchesSignature(Sheet sheet, String sheetName, AuditExcelCellReader reader) {
        if (sheetName == null || sheetName.isBlank()) {
            return false;
        }
        Row row = sheet.getRow(0);
        if (row == null) {
            return false;
        }
        if (!DEBT_KIND.equals(reader.readString(row.getCell(0)))) {
            return false;
        }
        String account = reader.readString(row.getCell(1));
        if (account == null || !account.equals(sheetName.trim())) {
            return false;
        }
        Integer orgNum = reader.readIntResult(row.getCell(COL_ORG_NUM)).value();
        if (orgNum == null) {
            return false;
        }
        String orgName = reader.readString(row.getCell(COL_ORG_NAME));
        if (orgName == null || orgName.isBlank()) {
            return false;
        }
        if (isBlank(reader.readString(row.getCell(COL_INV)))) {
            return false;
        }
        if (reader.readDate(row.getCell(COL_FORM)) == null) {
            return false;
        }
        if (reader.readDate(row.getCell(COL_MAT)) == null) {
            return false;
        }
        return reader.readDecimalResult(row.getCell(COL_DEBT)).ok();
    }
    
    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
