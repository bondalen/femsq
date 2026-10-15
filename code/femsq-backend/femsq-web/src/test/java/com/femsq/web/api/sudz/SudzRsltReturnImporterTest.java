package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltReturnRow;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Чтение полосы возврата Rslt: склейка ячеек и ординалы для Value.
 */
class SudzRsltReturnImporterTest {

    @Test
    void mergedBandKeepsTopCellWhenExcelClearsTheRest() throws Exception {
        byte[] book = workbook((sheet) -> {
            header(sheet);
            Row top = sheet.createRow(3);
            top.createCell(0).setCellValue(11897);
            top.createCell(1).setCellValue("Дедова И.В");
            top.createCell(2).setCellValue("решение суда");
            sheet.createRow(4);
            sheet.addMergedRegion(new CellRangeAddress(3, 4, 0, 0));
            sheet.addMergedRegion(new CellRangeAddress(3, 4, 1, 1));
            sheet.addMergedRegion(new CellRangeAddress(3, 4, 2, 2));
        });

        SudzRsltReturnParse parse = SudzRsltReturnImporter.parse(new ByteArrayInputStream(book));

        assertEquals(2, parse.sourceRows());
        assertEquals(List.of(11897), parse.sameTextKeys());
        assertTrue(parse.differentTextKeys().isEmpty());
        assertEquals(2, parse.rows().size());
        assertEquals(0, parse.rows().get(0).bandOrdinal());
        assertEquals(1, parse.rows().get(1).bandOrdinal());
        assertEquals("Дедова И.В", parse.rows().get(0).curatorNew());
        assertEquals("решение суда", parse.rows().get(1).meryNew());
    }

    @Test
    void differentTextsOnOneDebtKeepBothRows() {
        SudzRsltReturnParse parse = SudzRsltReturnImporter.collapse(List.of(
                new SudzRsltReturnRow(42, "А", "первое", null),
                new SudzRsltReturnRow(42, "Б", "второе", "051-1001888")
        ));

        assertEquals(List.of(42), parse.differentTextKeys());
        assertTrue(parse.sameTextKeys().isEmpty());
        assertEquals(2, parse.rows().size());
        assertEquals("А", parse.rows().get(0).curatorNew());
        assertEquals("первое", parse.rows().get(0).meryNew());
        assertEquals(0, parse.rows().get(0).bandOrdinal());
        assertEquals("Б", parse.rows().get(1).curatorNew());
        assertEquals("второе", parse.rows().get(1).meryNew());
        assertEquals("051-1001888", parse.rows().get(1).cstCodeNew());
        assertEquals(1, parse.rows().get(1).bandOrdinal());
    }

    @Test
    void formulaCodeIsReadByValue() throws Exception {
        byte[] book = workbook((sheet) -> {
            header(sheet);
            Row code = sheet.createRow(3);
            code.createCell(0).setCellValue(3672);
            code.createCell(3).setCellFormula("\"051-1001888\"");
        });

        SudzRsltReturnParse parse = SudzRsltReturnImporter.parse(new ByteArrayInputStream(book));

        assertEquals(1, parse.rows().size());
        assertEquals("051-1001888", parse.rows().get(0).cstCodeNew());
    }

    @Test
    void progressReplacesArchiveWithThisRun() {
        SudzRsltReturnParse parse = new SudzRsltReturnParse(
                List.of(
                        new SudzRsltReturnRow(11897, "А", "текст", null, 0),
                        new SudzRsltReturnRow(11897, "А", "текст", null, 1)
                ),
                2,
                List.of(11897),
                List.of()
        );
        String text = SudzRsltReturnProgress.success(
                "comm.xlsx",
                901,
                parse,
                new com.femsq.database.model.sudz.SudzRsltReturnImportResult(1, 1, 0, 0),
                LocalDateTime.of(2026, 10, 12, 14, 50, 0));

        assertTrue(text.startsWith("Rslt повтор · Загрузить\n"));
        assertTrue(text.contains("Прочитано строк с заполненными *_new: 2"));
        assertTrue(text.contains("Полоса, один и тот же текст: 11897"));
        assertTrue(text.contains("Строк полосы к записи: 2"));
        assertTrue(text.contains("Итог: записано долгов 1"));
        assertTrue(text.contains("Привязка Value: крайняя 1, walk-back 0, Acc 0"));

        String failed = SudzRsltReturnProgress.failure(
                "comm.xlsx",
                901,
                parse,
                "Код стройки не найден в ags.cstAgPn: AW27",
                LocalDateTime.of(2026, 10, 12, 14, 51, 0)
        );
        assertTrue(failed.contains("Итог: записано 0, откат"));
        assertTrue(failed.contains("AW27"));
    }

    private static void header(Sheet sheet) {
        Row tech = sheet.createRow(2);
        tech.createCell(0).setCellValue("dbtKey");
        tech.createCell(1).setCellValue("cur_new");
        tech.createCell(2).setCellValue("mery_new");
        tech.createCell(3).setCellValue("cstAgPn_new");
    }

    private static byte[] workbook(SheetWriter writer) throws IOException {
        try (XSSFWorkbook book = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            writer.write(book.createSheet("Rslt"));
            book.write(out);
            return out.toByteArray();
        }
    }

    @FunctionalInterface
    private interface SheetWriter {
        void write(Sheet sheet);
    }
}
