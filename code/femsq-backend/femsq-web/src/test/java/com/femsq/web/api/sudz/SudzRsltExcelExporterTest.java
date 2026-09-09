package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * S77.5: полоса A — 2×18000 факта, погашено на ∑ канона, merge зерна 1.
 */
class SudzRsltExcelExporterTest {

    @Test
    void pogashenoIgnoresShareDelta() {
        assertNull(SudzRsltExcelExporter.pogashenoAccess(
                new BigDecimal("36000"), new BigDecimal("36000")));
        assertEquals(0, new BigDecimal("6000").compareTo(
                SudzRsltExcelExporter.pogashenoAccess(
                        new BigDecimal("36000"), new BigDecimal("30000"))));
    }

    @Test
    void bandASplitDoesNotInventPogashenoPerShare() throws Exception {
        LocalDate qiv = LocalDate.parse("2025-12-31");
        LocalDate qi = LocalDate.parse("2026-03-31");
        SudzRsltDebt debt = new SudzRsltDebt(
                11897,
                "76.10",
                "куратор",
                "мероприятие",
                null,
                null,
                null,
                null,
                null,
                List.of(
                        period(910, qiv, 0, "А45-19974/2024", "36000"),
                        period(901, qi, 1, "А45-19974/2024", "18000"),
                        period(901, qi, 2, "А45-19974/2024", "18000")
                )
        );
        byte[] xlsx = SudzRsltExcelExporter.exportRsltSborn(List.of(debt));
        try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(xlsx))) {
            Sheet sheet = wb.getSheet("Rslt");
            assertEquals(2, sheet.getLastRowNum() - 2);
            assertEquals(11897, (int) sheet.getRow(3).getCell(0).getNumericCellValue());
            assertEquals(36000.0, sheet.getRow(3).getCell(10).getNumericCellValue(), 0.001);
            assertEquals(1, (int) sheet.getRow(3).getCell(17).getNumericCellValue());
            assertEquals(18000.0, sheet.getRow(3).getCell(24).getNumericCellValue(), 0.001);
            assertEquals(2, (int) sheet.getRow(4).getCell(17).getNumericCellValue());
            assertEquals(18000.0, sheet.getRow(4).getCell(24).getNumericCellValue(), 0.001);
            assertTrue(sheet.getRow(3).getCell(30) == null
                    || sheet.getRow(3).getCell(30).getCellType().name().equals("BLANK")
                    || Double.isNaN(safeNum(sheet, 3, 30)));
            assertTrue(merged(sheet, 3, 4, 0));
            assertTrue(merged(sheet, 3, 4, 10));
            assertTrue(merged(sheet, 3, 4, 30));
        }
    }

    private static double safeNum(Sheet sheet, int row, int col) {
        var cell = sheet.getRow(row).getCell(col);
        if (cell == null) {
            return Double.NaN;
        }
        return switch (cell.getCellType()) {
            case NUMERIC -> cell.getNumericCellValue();
            case BLANK, STRING, FORMULA, BOOLEAN, ERROR, _NONE -> Double.NaN;
        };
    }

    private static boolean merged(Sheet sheet, int r1, int r2, int col) {
        for (int i = 0; i < sheet.getNumMergedRegions(); i++) {
            CellRangeAddress a = sheet.getMergedRegion(i);
            if (a.getFirstColumn() == col && a.getLastColumn() == col
                    && a.getFirstRow() == r1 && a.getLastRow() == r2) {
                return true;
            }
        }
        return false;
    }

    private static SudzRsltPeriod period(int upl, LocalDate date, int idNum, String inv, String ttl) {
        BigDecimal v = new BigDecimal(ttl);
        return new SudzRsltPeriod(
                upl, date, date, inv, idNum, "32-426", null, null, null, "контрагент",
                null, v, v, null, null, null, null);
    }
}
