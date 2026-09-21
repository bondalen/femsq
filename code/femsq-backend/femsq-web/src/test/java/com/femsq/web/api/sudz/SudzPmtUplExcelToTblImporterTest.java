package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
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
 * Excel→Tbl платежей: якорь «№ докум.» + колонки по ключевым словам заголовков.
 */
class SudzPmtUplExcelToTblImporterTest {

    private SudzPmtUplExcelToTblImporter importer;

    @BeforeEach
    void setUp() {
        importer = new SudzPmtUplExcelToTblImporter(new AuditExcelCellReader());
    }

    @Test
    void parseCanonLayoutProducesTblRows() throws IOException {
        byte[] bytes = canonWorkbookBytes();
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
        assertTrue(html.contains("колонки по заголовкам"));
        assertFalse(html.contains("книга Excel открыта"));
        assertFalse(html.contains("добавлено"));
    }

    @Test
    void parseNew767LayoutResolvesByHeaderKeywords() throws IOException {
        byte[] bytes = new767WorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_767501.xlsx", "Sheet1", 55, log);

        assertEquals(1, rows.size());
        SudzPmtUplTblRow row = rows.get(0);
        assertEquals("0001", row.ciputBE());
        assertEquals(767501, row.ciputAccount());
        assertEquals(28, row.ciputCntrPrtNum());
        assertEquals("Кредитор ВГ", row.ciputCntrPrtName());
        assertEquals("CST-9", row.ciputCAC());
        assertEquals("CN-77", row.ciputCnName());
        assertEquals(100, row.ciputAgentNum());
        assertEquals("Агент Имя", row.ciputAgentName());
        assertEquals("LINK-1", row.ciputLink());
        assertEquals("INV-9", row.ciputCnInv());
        assertEquals("PD-55", row.ciputCnInvDocCode());
        assertNull(row.ciputDueDate());
        assertNull(row.ciputCnInvDocSum());
        assertTrue(log.toHtml().contains("колонки по заголовкам"));
        assertFalse(log.toHtml().contains("слишком близко к левому краю"));
    }

    @Test
    void missingSheetYieldsEmpty() throws IOException {
        byte[] bytes = canonWorkbookBytes();
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

    @Test
    void normalizeHeaderStripsPunctuation() {
        assertEquals("№докум", SudzPmtUplExcelToTblImporter.normalizeHeader("№ докум."));
        assertEquals("сальдоконечноедт", SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо конечное Дт"));
        assertEquals("дпроводки", SudzPmtUplExcelToTblImporter.normalizeHeader("Д/проводки"));
    }

    private static byte[] canonWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeCanonHeader(sheet.createRow(0));
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

    /** Layout как export_767501_26-0817.raw (якорь «№ докум.» @ col 18). */
    private static byte[] new767WorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            String[] titles = {
                    "БЕ", "Опер.сегмент", "Код стройки", "Счет ГК", "Вид контрагента",
                    "Кредитор", "Наименование кредитора", "Договор", "Агент", "Агент",
                    "Сальдо начальное Дт", "Сальдо начальное по Кт", "Сальдо начальное",
                    "Дебетовый оборот", "Кредитовый оборот",
                    "Сальдо конечное Дт", "Сальдо конечное по Кт", "Сальдо конечное",
                    SudzPmtUplExcelToTblImporter.ANCHOR_DOC_NUM,
                    "Д/проводки", "Д/документ", "Д/выравн.", "Ссылка", "Присвоение",
                    "Д/К", "КС", "Нулевые показатели", "Частичное выравнивание",
                    "ПричСторн", "ДокСторно"
            };
            Row header = sheet.createRow(0);
            for (int c = 0; c < titles.length; c++) {
                header.createCell(c).setCellValue(titles[c]);
            }
            Row data = sheet.createRow(1);
            data.createCell(0).setCellValue("0001");
            data.createCell(2).setCellValue("CST-9");
            data.createCell(3).setCellValue(767501);
            data.createCell(5).setCellValue(28);
            data.createCell(6).setCellValue("Кредитор ВГ");
            data.createCell(7).setCellValue("CN-77");
            data.createCell(8).setCellValue(100);
            data.createCell(9).setCellValue("Агент Имя");
            data.createCell(15).setCellValue(10.0);
            data.createCell(16).setCellValue(0.0);
            data.createCell(17).setCellValue(10.0);
            data.createCell(18).setCellValue("PD-55");
            data.createCell(22).setCellValue("LINK-1");
            data.createCell(23).setCellValue("INV-9");
            return toBytes(wb);
        }
    }

    private static byte[] workbookWithWeakRow() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeCanonHeader(sheet.createRow(0));
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

    private static void writeCanonHeader(Row header) {
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
