package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.model.sudz.SudzDbtUplFileSh;
import com.femsq.database.model.sudz.SudzDbtUplTblRow;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Разбор excelToTbl: компактная раскладка без шапки (QII 606012).
 */
class SudzDbtUplExcelToTblImporterTest {

    private AuditExcelCellReader cellReader;
    private SudzDbtUplExcelToTblImporter importer;

    @BeforeEach
    void setUp() {
        cellReader = new AuditExcelCellReader();
        importer = new SudzDbtUplExcelToTblImporter(cellReader);
    }

    @Test
    void compactSignatureMatchesQii606012Row() throws IOException {
        byte[] bytes = compactWorkbookBytes();
        try (var wb = org.apache.poi.ss.usermodel.WorkbookFactory.create(
                new java.io.ByteArrayInputStream(bytes))) {
            var sheet = wb.getSheet("606012");
            assertTrue(SudzDbtUplExcelCompactLayout.matchesSignature(sheet, "606012", cellReader));
        }
    }

    @Test
    void compactSignatureRejectsStandardHeaderSheet() throws IOException {
        byte[] bytes = standardWorkbookBytes();
        try (var wb = org.apache.poi.ss.usermodel.WorkbookFactory.create(
                new java.io.ByteArrayInputStream(bytes))) {
            var sheet = wb.getSheet("606012");
            assertFalse(SudzDbtUplExcelCompactLayout.matchesSignature(sheet, "606012", cellReader));
        }
    }

    @Test
    void parseCompact606012ProducesTblRows() throws IOException {
        byte[] bytes = compactWorkbookBytes();
        SudzDbtUplFileSh fileSh = new SudzDbtUplFileSh(1, 24, "606012", 19, true, 606012);
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzDbtUplTblRow> rows = importer.parse(bytes, "test.xlsx", List.of(fileSh), 903, log);

        assertEquals(2, rows.size());
        SudzDbtUplTblRow first = rows.get(0);
        assertEquals(1000139, first.cidutCntrPrtNum());
        assertEquals("ООО ТЕСТ", first.cidutCntrPrtName());
        assertEquals("1", first.cidutCnName());
        assertEquals("100042", first.cidutCnInv());
        assertEquals(new BigDecimal("166666666.67"), first.cidutDebt());
        assertEquals(903, first.cidutUnloadKey());
        assertTrue(log.toHtml().contains("компактный формат без шапки"));
    }

    private static byte[] compactWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            var sheet = wb.createSheet("606012");
            writeCompactRow(sheet.createRow(0), "100042", "166666666.67");
            writeCompactRow(sheet.createRow(1), "100113", "41666666.67");
            return toBytes(wb);
        }
    }

    private static byte[] standardWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            var sheet = wb.createSheet("606012");
            var header = sheet.createRow(0);
            header.createCell(0).setCellValue("Вид задолженности");
            header.createCell(7).setCellValue("Документ основания (счет-фактура)");
            header.createCell(4).setCellValue("№ контрагента");
            header.createCell(2).setCellValue("Контрагент");
            header.createCell(5).setCellValue("Договор");
            header.createCell(8).setCellValue("Дата образования");
            header.createCell(9).setCellValue("Срок погашения");
            header.createCell(10).setCellValue("Всего сумма задолженности в рублях");
            header.createCell(11).setCellValue("Просроченная задолженность в рублях");
            writeCompactRow(sheet.createRow(1), "100042", "166666666.67");
            return toBytes(wb);
        }
    }

    private static void writeCompactRow(org.apache.poi.ss.usermodel.Row row, String inv, String debt) {
        row.createCell(0).setCellValue("D");
        row.createCell(1).setCellValue("606012");
        row.createCell(2).setCellValue(1000139);
        row.createCell(3).setCellValue("ООО ТЕСТ");
        row.createCell(4).setCellValue("1");
        row.createCell(5).setCellValue(inv);
        row.createCell(6).setCellValue("19.09.2025");
        row.createCell(7).setCellValue("31.12.2026");
        row.createCell(8).setCellValue(new BigDecimal(debt).doubleValue());
        row.createCell(9).setCellValue(0);
    }

    private static byte[] toBytes(XSSFWorkbook wb) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        return out.toByteArray();
    }
}
