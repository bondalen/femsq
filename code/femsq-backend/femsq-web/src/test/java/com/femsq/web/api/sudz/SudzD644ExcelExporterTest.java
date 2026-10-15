package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzD644Row;
import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Полоса Д644: зерно базы, среза и комментария.
 */
class SudzD644ExcelExporterTest {

    private static final int COL_OVERD_BASE = 11;
    private static final int COL_OVERD_CURR = 13;
    private static final int COL_COMMENT = 17;

    @Test
    void equalSharesStayTwoRowsWithTwoComments() throws Exception {
        byte[] book = SudzD644ExcelExporter.exportD644(List.of(
                row(11897, 1, "18 000 A", money(18000), money(18000), "суд", 1, 1, 1, 1),
                row(11897, 2, "18 000 B", money(18000), money(18000), "суд", 1, 1, 1, 0)
        ));
        try (XSSFWorkbook workbook = new XSSFWorkbook(new ByteArrayInputStream(book))) {
            Sheet sheet = workbook.getSheetAt(0);
            assertEquals(18000d, sheet.getRow(4).getCell(COL_OVERD_BASE).getNumericCellValue());
            assertEquals(18000d, sheet.getRow(5).getCell(COL_OVERD_BASE).getNumericCellValue());
            assertEquals("суд", sheet.getRow(4).getCell(COL_COMMENT).getStringCellValue());
            assertEquals("суд", sheet.getRow(5).getCell(COL_COMMENT).getStringCellValue());
            assertFalse(merged(sheet, 4, COL_COMMENT));
            assertFalse(merged(sheet, 4, COL_OVERD_CURR));
        }
    }

    @Test
    void oneBaseShareSplitsForTwoSliceRowsAndKeepsTwoComments() throws Exception {
        // 1+2: cmm_span = зерно среза → две ячейки комментария (не merge).
        byte[] book = SudzD644ExcelExporter.exportD644(List.of(
                row(1, 1, "база", money(100), money(40), "доля A", 2, 1, 1, 2),
                row(1, 2, null, null, money(60), "доля B", 0, 1, 1, 0)
        ));
        try (XSSFWorkbook workbook = new XSSFWorkbook(new ByteArrayInputStream(book))) {
            Sheet sheet = workbook.getSheetAt(0);
            assertTrue(merged(sheet, 4, COL_OVERD_BASE));
            assertFalse(merged(sheet, 4, COL_COMMENT));
            assertFalse(merged(sheet, 4, COL_OVERD_CURR));
            assertEquals("доля A", sheet.getRow(4).getCell(COL_COMMENT).getStringCellValue());
            assertEquals("доля B", sheet.getRow(5).getCell(COL_COMMENT).getStringCellValue());
            assertEquals(40d, sheet.getRow(4).getCell(COL_OVERD_CURR).getNumericCellValue());
            assertEquals(60d, sheet.getRow(5).getCell(COL_OVERD_CURR).getNumericCellValue());
        }
    }

    @Test
    void twoBaseSharesMergeOneSliceRowAndMergeComment() throws Exception {
        // 2+1: cmm_span = зерно среза (1) → один комментарий на полосу.
        byte[] book = SudzD644ExcelExporter.exportD644(List.of(
                row(2, 1, "доля 1", money(10), money(7), "общий", 1, 2, 2, 2),
                row(2, 2, "доля 2", money(20), null, null, 1, 0, 0, 0)
        ));
        try (XSSFWorkbook workbook = new XSSFWorkbook(new ByteArrayInputStream(book))) {
            Sheet sheet = workbook.getSheetAt(0);
            assertTrue(merged(sheet, 4, COL_OVERD_CURR));
            assertTrue(merged(sheet, 4, COL_COMMENT));
            assertEquals("общий", sheet.getRow(4).getCell(COL_COMMENT).getStringCellValue());
            assertEquals(10d, sheet.getRow(4).getCell(COL_OVERD_BASE).getNumericCellValue());
            assertEquals(20d, sheet.getRow(5).getCell(COL_OVERD_BASE).getNumericCellValue());
        }
    }

    private static boolean merged(Sheet sheet, int row, int column) {
        for (CellRangeAddress region : sheet.getMergedRegions()) {
            if (region.getFirstRow() == row && region.getFirstColumn() == column && region.getLastRow() > row) {
                return true;
            }
        }
        return false;
    }

    private static BigDecimal money(long value) {
        return BigDecimal.valueOf(value);
    }

    private static SudzD644Row row(
            int dbtKey,
            int bandRn,
            String contract,
            BigDecimal overdBase,
            BigDecimal overdCurr,
            String comment,
            int baseSpan,
            int currSpan,
            int commentSpan,
            int repaidSpan
    ) {
        return new SudzD644Row(
                dbtKey,
                762210,
                null,
                null,
                null,
                "контрагент",
                contract,
                null,
                "СФ",
                null,
                null,
                overdBase,
                overdBase,
                null,
                overdCurr,
                null,
                "051-2000707",
                null,
                comment,
                LocalDate.of(2026, 1, 15),
                LocalDate.of(2026, 7, 15),
                901,
                903,
                bandRn,
                baseSpan,
                currSpan,
                commentSpan,
                repaidSpan
        );
    }
}
