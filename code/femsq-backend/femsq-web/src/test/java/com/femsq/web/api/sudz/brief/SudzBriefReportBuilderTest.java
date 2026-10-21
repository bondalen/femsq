package com.femsq.web.api.sudz.brief;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Сборка краткого отчёта из минимального свода (два счёта).
 */
class SudzBriefReportBuilderTest {

    @TempDir
    Path temp;

    @Test
    void buildsReportBesideSvodWithCanonicalOrderAndTotals() throws Exception {
        Path svod = temp.resolve("svod-test.xlsx");
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet a = wb.createSheet("601300");
            Row h = a.createRow(0);
            h.createCell(1).setCellValue("Счёт");
            Row r1 = a.createRow(1);
            r1.createCell(0).setCellValue("D");
            r1.createCell(1).setCellValue("601300");
            r1.createCell(2).setCellValue("Иванов Иван Иванович");
            r1.createCell(4).setCellValue("1");
            r1.createCell(5).setCellValue("Д-1");
            r1.createCell(7).setCellValue("док");
            r1.createCell(10).setCellValue(100.0);
            r1.createCell(11).setCellValue(40.0);
            // строка без D — не должна попасть в отчёт
            Row skip = a.createRow(2);
            skip.createCell(0).setCellValue("");
            skip.createCell(1).setCellValue("601300");
            skip.createCell(2).setCellValue("Мусор");
            skip.createCell(10).setCellValue(999.0);

            Sheet b = wb.createSheet("767501");
            Row hb = b.createRow(0);
            hb.createCell(1).setCellValue("Счёт");
            Row r2 = b.createRow(1);
            r2.createCell(0).setCellValue("D");
            r2.createCell(1).setCellValue("767501");
            r2.createCell(2).setCellValue("ООО Тест");
            r2.createCell(4).setCellValue("2");
            r2.createCell(5).setCellValue("Д-2");
            r2.createCell(7).setCellValue("док2");
            r2.createCell(10).setCellValue(50.0);
            r2.createCell(11).setCellValue(0.0);

            wb.createSheet("767402 нет");
            try (OutputStream os = Files.newOutputStream(svod)) {
                wb.write(os);
            }
        }

        FioByDictionary fio = new FioByDictionary(List.of("Иван", "Иванович"));
        SudzBriefReportBuilder builder = new SudzBriefReportBuilder();
        SudzBriefReportResult result = builder.build(svod, LocalDate.of(2026, 3, 31), fio);

        assertTrue(Files.isRegularFile(Path.of(result.outputPath())));
        assertEquals(List.of("601300", "767501"), result.accountBlocks());
        assertEquals(150.0, result.totalDebtH(), 0.001);
        assertEquals(40.0, result.totalOverdueI(), 0.001);
        assertEquals(110.0, result.totalNotOverdueK(), 0.001);
        assertEquals(1, result.fioTransformed());
        assertTrue(result.fioSkipWordcount() >= 1);
        assertTrue(result.outputPath().endsWith("svod-test_краткий_отчёт.xlsx"));

        try (XSSFWorkbook out = new XSSFWorkbook(Files.newInputStream(Path.of(result.outputPath())))) {
            Sheet sheet = out.getSheetAt(0);
            Row overdueRow = sheet.getRow(6);
            assertEquals("Иванов И.И.", overdueRow.getCell(2).getStringCellValue());
            assertEquals(40.0, overdueRow.getCell(8).getNumericCellValue(), 0.001);
            assertEquals(60.0, overdueRow.getCell(10).getNumericCellValue(), 0.001);
            // без срока погашения дни = 0 → J пусто (как 2_ready: нет отрицательных/нулевых дней)
            assertNull(overdueRow.getCell(9));

            Row notOverdue = sheet.getRow(8); // после ИТОГО 601300
            // найти строку ООО Тест
            Row ooo = null;
            for (int r = 6; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row != null && row.getCell(2) != null
                        && "ООО Тест".equals(row.getCell(2).getStringCellValue())) {
                    ooo = row;
                    break;
                }
            }
            assertTrue(ooo != null);
            assertNull(ooo.getCell(8), "I пусто при нулевой просрочке");
            assertNull(ooo.getCell(9), "J пусто при нулевой просрочке");
            assertEquals(50.0, ooo.getCell(10).getNumericCellValue(), 0.001);

            assertTrue(sheet.getColumnWidth(2) > 40 * 256);
            assertTrue(sheet.getRow(0).getCell(10).getStringCellValue().startsWith("Приложение № 1"));
            assertEquals(1, sheet.getNumMergedRegions());
            assertEquals("Отчет по дебиторской задолженности",
                    sheet.getRow(2).getCell(0).getStringCellValue());
            String moneyFmt = overdueRow.getCell(7).getCellStyle().getDataFormatString();
            assertTrue(moneyFmt.contains("0.00"), "money fmt=" + moneyFmt);
            assertTrue(sheet.getRow(5).getHeightInPoints() >= 70f);
        }
    }
}
