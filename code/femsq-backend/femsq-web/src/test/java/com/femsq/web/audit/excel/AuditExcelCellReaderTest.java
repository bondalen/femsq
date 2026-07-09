package com.femsq.web.audit.excel;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit-тесты устойчивого чтения ячеек Excel ({@link CellReadResult}).
 */
class AuditExcelCellReaderTest {

    private AuditExcelCellReader reader;
    private XSSFWorkbook workbook;

    @BeforeEach
    void setUp() {
        reader = new AuditExcelCellReader();
        workbook = new XSSFWorkbook();
    }

    @AfterEach
    void tearDown() throws Exception {
        workbook.close();
    }

    @Test
    void readIntResult_textInsteadOfNumber_returnsFailureWithoutThrowing() {
        Cell cell = stringCell("в электронном виде");

        CellReadResult<Integer> result = reader.readIntResult(cell);

        assertFalse(result.ok());
        assertNull(result.value());
        assertEquals("в электронном виде", result.rawText());
        assertEquals("целое число", result.expectedType());
    }

    @Test
    void readIntResult_validInteger_returnsValue() {
        Cell cell = numericCell(42);

        CellReadResult<Integer> result = reader.readIntResult(cell);

        assertTrue(result.ok());
        assertEquals(42, result.value());
    }

    @Test
    void readIntResult_dash_returnsNullSuccess() {
        Cell cell = stringCell("—");

        CellReadResult<Integer> result = reader.readIntResult(cell);

        assertTrue(result.ok());
        assertNull(result.value());
    }

    @Test
    void readDecimalResult_invalidText_returnsFailure() {
        Cell cell = stringCell("не число");

        CellReadResult<java.math.BigDecimal> result = reader.readDecimalResult(cell);

        assertFalse(result.ok());
        assertEquals("число", result.expectedType());
    }

    @Test
    void readInt_strictMode_stillThrows() {
        Cell cell = stringCell("в электронном виде");

        assertThrows(AuditExcelException.class, () -> reader.readInt(cell));
    }

    private Cell stringCell(String value) {
        var sheet = workbook.createSheet();
        var row = sheet.createRow(0);
        var cell = row.createCell(0);
        cell.setCellValue(value);
        return cell;
    }

    private Cell numericCell(int value) {
        var sheet = workbook.createSheet();
        var row = sheet.createRow(0);
        var cell = row.createCell(0);
        cell.setCellValue(value);
        return cell;
    }
}
