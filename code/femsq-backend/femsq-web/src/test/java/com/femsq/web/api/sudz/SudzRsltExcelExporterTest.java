package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * S77.5: полоса A — 2×18000 факта, погашено на ∑ канона, merge зерна 1.
 * Порядок cmm: «старые» после предшествующего среза, {@code *_new} в конце.
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
            int ttlBase = col(sheet, qiv + "_Ttl");
            int idQi = col(sheet, qi + "_idNum");
            int overdQi = col(sheet, qi + "_Overd");
            int pog = col(sheet, qi + "_погашено");
            int oldCur = col(sheet, "Куратор от Управления");
            int curNew = col(sheet, "cur_new");
            assertEquals(36000.0, sheet.getRow(3).getCell(ttlBase).getNumericCellValue(), 0.001);
            assertEquals(1, (int) sheet.getRow(3).getCell(idQi).getNumericCellValue());
            assertEquals(18000.0, sheet.getRow(3).getCell(overdQi).getNumericCellValue(), 0.001);
            assertEquals(2, (int) sheet.getRow(4).getCell(idQi).getNumericCellValue());
            assertEquals(18000.0, sheet.getRow(4).getCell(overdQi).getNumericCellValue(), 0.001);
            assertTrue(sheet.getRow(3).getCell(pog) == null
                    || sheet.getRow(3).getCell(pog).getCellType().name().equals("BLANK")
                    || Double.isNaN(safeNum(sheet, 3, pog)));
            assertTrue(merged(sheet, 3, 4, 0));
            assertTrue(merged(sheet, 3, 4, ttlBase));
            assertTrue(merged(sheet, 3, 4, pog)); // погашено зерно 1
            // «старые» без *Dv — зерно InvAccnt = 1 → merge; *_new пустые по 2 Value крайней — без merge
            assertTrue(merged(sheet, 3, 4, oldCur));
            assertTrue(!merged(sheet, 3, 4, curNew));
            // «старые» стоят до фактов крайней upl
            assertTrue(oldCur < idQi);
            assertTrue(curNew > pog);
            // Дата договора QI: настоящая Excel-дата, формат dd.MM.yyyy
            var cnDate = sheet.getRow(3).getCell(col(sheet, qi + "_csoCnDate"));
            assertEquals(org.apache.poi.ss.usermodel.CellType.NUMERIC, cnDate.getCellType());
            assertTrue(org.apache.poi.ss.usermodel.DateUtil.isCellDateFormatted(cnDate));
            assertTrue(cnDate.getCellStyle().getDataFormatString().contains("dd.MM.yyyy")
                    || cnDate.getCellStyle().getDataFormatString().contains("DD.MM.YYYY"));
            // Деньги без символа рубля, разделители #,##0.00 сохранены
            String moneyFmt = sheet.getRow(3).getCell(ttlBase).getCellStyle().getDataFormatString();
            assertTrue(moneyFmt.contains("#,##0.00"));
            assertTrue(!moneyFmt.contains("₽") && !moneyFmt.contains("[$"));
        }
    }

    private static int col(Sheet sheet, String techName) {
        Row tech = sheet.getRow(2);
        for (Cell cell : tech) {
            if (cell != null && techName.equals(cell.getStringCellValue())) {
                return cell.getColumnIndex();
            }
        }
        throw new AssertionError("column not found: " + techName);
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
                upl, date, date, inv, idNum, "32-426", date, null, null, "контрагент",
                date, v, v, null, null, null, null,
                null, null, null, null, null, null, null, null);
    }

    @Test
    void emptyNewColumnsFollowExtremeValueGrain() throws Exception {
        LocalDate qiv = LocalDate.parse("2025-12-31");
        LocalDate qi = LocalDate.parse("2026-03-31");
        SudzRsltDebt debt = new SudzRsltDebt(
                1, "76.10", "куратор", "мероприятие", null, null, null, null, null,
                List.of(
                        period(910, qiv, 0, "А1", "100"),
                        period(901, qi, 1, "А1", "50"),
                        period(901, qi, 2, "А1", "50")
                )
        );
        byte[] xlsx = SudzRsltExcelExporter.exportRsltSborn(List.of(debt));
        try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(xlsx))) {
            Sheet sheet = wb.getSheet("Rslt");
            // cur_new / mery_new / cstAgPn_new — три последние колонки; зерно 2 → без merge
            int lastCol = sheet.getRow(2).getLastCellNum() - 1;
            assertEquals("cstAgPn_new", sheet.getRow(2).getCell(lastCol).getStringCellValue());
            assertTrue(!merged(sheet, 3, 4, lastCol));
            assertTrue(!merged(sheet, 3, 4, lastCol - 1));
            assertTrue(!merged(sheet, 3, 4, lastCol - 2));
        }
    }

    @Test
    void periodDvCommentsWriteOneCellPerValue() throws Exception {
        LocalDate qiv = LocalDate.parse("2025-12-31");
        LocalDate qi = LocalDate.parse("2026-03-31");
        SudzRsltDebt debt = new SudzRsltDebt(
                2, "76.10", null, null, null, null, null, null, null,
                List.of(
                        new SudzRsltPeriod(
                                910, qiv, qiv, "А1", 0, null, null, null, null, null,
                                null, new BigDecimal("100"), new BigDecimal("100"),
                                null, null, null, null,
                                10, "К1", "М1", null, null, null, null, null),
                        new SudzRsltPeriod(
                                901, qi, qi, "А1", 1, null, null, null, null, null,
                                null, new BigDecimal("50"), new BigDecimal("50"),
                                null, null, null, null,
                                11, null, null, null, null, "Кн1", "Мн1", null),
                        new SudzRsltPeriod(
                                901, qi, qi, "А1", 2, null, null, null, null, null,
                                null, new BigDecimal("50"), new BigDecimal("50"),
                                null, null, null, null,
                                12, null, null, null, null, "Кн2", "Мн2", null)
                )
        );
        byte[] xlsx = SudzRsltExcelExporter.exportRsltPovtor(List.of(debt));
        try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(xlsx))) {
            Sheet sheet = wb.getSheet("Rslt");
            int meryNew = col(sheet, "mery_new");
            int meryOld = col(sheet, "Мероприятия по погашению дебиторской задолженности");
            int idQi = col(sheet, qi + "_idNum");
            assertEquals("Мн1", sheet.getRow(3).getCell(meryNew).getStringCellValue());
            assertEquals("Мн2", sheet.getRow(4).getCell(meryNew).getStringCellValue());
            assertTrue(!merged(sheet, 3, 4, meryNew));
            // старые с предшествующего (910): зерно 1 → merge; колонка до фактов крайней
            assertEquals("М1", sheet.getRow(3).getCell(meryOld).getStringCellValue());
            assertTrue(merged(sheet, 3, 4, meryOld));
            assertTrue(meryOld < idQi);
            assertTrue(meryNew > idQi);
        }
    }

    @Test
    void precedingSliceIndexRules() {
        assertEquals(-1, SudzRsltExcelExporter.precedingSliceIndex(0));
        assertEquals(0, SudzRsltExcelExporter.precedingSliceIndex(1));
        assertEquals(0, SudzRsltExcelExporter.precedingSliceIndex(2));
        assertEquals(1, SudzRsltExcelExporter.precedingSliceIndex(3));
    }
}
