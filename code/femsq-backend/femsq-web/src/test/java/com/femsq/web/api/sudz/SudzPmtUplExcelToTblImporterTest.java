package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzPmtUplTblRow;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Excel→Tbl платежей: якорь «№ докум.», Offset A–Z, сжатый лог.
 */
class SudzPmtUplExcelToTblImporterTest {

    private SudzPmtUplExcelToTblImporter importer;

    @BeforeEach
    void setUp() {
        importer = new SudzPmtUplExcelToTblImporter(new AuditExcelCellReader());
    }

    @Test
    void parseOffsetMapProducesTblRows() throws IOException {
        byte[] bytes = offsetWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Sheet1", 2, log);

        assertEquals(1, rows.size());
        SudzPmtUplTblRow row = rows.get(0);
        assertEquals("BE01", row.ciputBE());
        assertEquals(606012, row.ciputAccount());
        assertEquals(1001, row.ciputCntrPrtNum());
        assertEquals("Кредитор Тест", row.ciputCntrPrtName());
        assertEquals("CAC-1", row.ciputCAC());
        assertEquals("Договор-1", row.ciputCnName());
        assertEquals("DOC-42", row.ciputCnInvDocCode());
        assertEquals(0, new BigDecimal("100.50").compareTo(row.ciputCnInvDocSum()));
        assertEquals(2, row.ciputUnloadKey());
        assertEquals(1, row.ciputSheetNum());

        String html = log.toHtml();
        assertTrue(html.contains("Sheet1"));
        assertTrue(html.contains("подготовлено"));
        assertFalse(html.contains("книга Excel открыта"));
        assertFalse(html.contains("добавлено"));
        assertFalse(html.contains("файл *"));
    }

    @Test
    void missingSheetYieldsEmpty() throws IOException {
        byte[] bytes = offsetWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Other", 2, log);
        assertEquals(0, rows.size());
        assertTrue(log.toHtml().contains("не найден"));
        assertTrue(log.toHtml().contains("итог"));
    }

    @Test
    void weakRowsCountedWithoutPerLineNoise() throws IOException {
        byte[] bytes = workbookWithWeakRow();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Sheet1", 2, log);
        assertEquals(2, rows.size());
        String html = log.toHtml();
        assertTrue(html.contains("без «№ докум.»: 1"));
        assertFalse(html.contains("добавлено"));
    }

    private static byte[] offsetWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeHeader(sheet.createRow(0));
            Row data = sheet.createRow(1);
            data.createCell(0).setCellValue("BE01");
            data.createCell(1).setCellValue(606012);
            data.createCell(2).setCellValue(1001);
            data.createCell(3).setCellValue("Кредитор Тест");
            data.createCell(4).setCellValue("CAC-1");
            data.createCell(7).setCellValue("Договор-1");
            data.createCell(20).setCellValue("DOC-42");
            data.createCell(23).setCellValue(100.50);
            return toBytes(wb);
        }
    }

    private static byte[] workbookWithWeakRow() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeHeader(sheet.createRow(0));
            Row ok = sheet.createRow(1);
            ok.createCell(0).setCellValue("BE01");
            ok.createCell(1).setCellValue(606012);
            ok.createCell(20).setCellValue("DOC-1");
            Row weak = sheet.createRow(2);
            weak.createCell(1).setCellValue(606012);
            weak.createCell(3).setCellValue("Без номера документа");
            return toBytes(wb);
        }
    }

    private static void writeHeader(Row header) {
        String[] titles = {
                "БЕ", "Счет ГК", "Кредитор", "Наименование кредитора", "Код стройки",
                "Агент", "Агент", "Договор", "Ссылка", "Присвоение",
                "Д/проводки", "Д/документ", "Срок оплаты",
                "Сальдо конечное Дт", "Сальдо кон.Дт просроченное", "Сальдо кон.Дт непросроченн.",
                "Сальдо конечное по Кт", "Сальдо кон.Кт просроченное", "Сальдо кон.Кт непросроченн.",
                "Сальдо конечное",
                SudzPmtUplExcelToTblImporter.ANCHOR_DOC_NUM,
                "Д/выравн.", "БазДата", "Сумма документа", "ПричСторн", "ДокСторно"
        };
        for (int c = 0; c < titles.length; c++) {
            header.createCell(c).setCellValue(titles[c]);
        }
    }

    private static byte[] toBytes(XSSFWorkbook wb) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        return out.toByteArray();
    }
}
