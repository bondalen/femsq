package com.femsq.web.api.sudz.brief;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

/**
 * Smoke QI 2026_03 vs эталон §7 (U1/U4/U6–U7/U9): путь свода на шаре nb-win.
 */
class SudzBriefReportQiSmokeTest {

    private static final Path SVOD = Path.of(
            "/mnt/nb-win-share/femsq/excel/2026_03/debit/"
                    + "Дт Задолженность на 31.03.2026 (Общий свод) -НОВЫЙ.xlsx");
    private static final Path WORDS = Path.of("/tmp/femsq-brief-smoke/fio-words.txt");
    private static final double TOL = 0.02;

    @Test
    void prepareQiMatchesReadyTotalsAndSampleFio() throws Exception {
        assumeTrue(Files.isRegularFile(SVOD), "нет свода QI на шаре");
        assumeTrue(Files.isRegularFile(WORDS), "нет дампа словаря /tmp/femsq-brief-smoke/fio-words.txt");

        List<String> words = Files.readAllLines(WORDS, StandardCharsets.UTF_8).stream()
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
        assumeTrue(words.size() >= 400, "словарь слишком мал: " + words.size());

        Path outBeside = SudzBriefReportBuilder.outputPathBeside(SVOD);
        if (Files.exists(outBeside)) {
            Files.delete(outBeside);
        }

        SudzBriefReportResult result = new SudzBriefReportBuilder()
                .build(SVOD, LocalDate.of(2026, 3, 31), new FioByDictionary(words));

        assertTrue(Files.isRegularFile(Path.of(result.outputPath())));
        assertEquals(12, result.accountBlocks().size());
        assertEquals(SudzBriefReportBuilder.CANONICAL_ACCOUNTS, result.accountBlocks());
        assertEquals(476_384_718_528.37, result.totalDebtH(), TOL);
        assertEquals(13_772_277_154.65, result.totalOverdueI(), TOL);
        assertEquals(462_612_441_373.72, result.totalNotOverdueK(), TOL);
        assertTrue(result.fioTransformed() > 0);

        try (XSSFWorkbook wb = new XSSFWorkbook(Files.newInputStream(Path.of(result.outputPath())))) {
            Sheet sheet = wb.getSheetAt(0);
            assertEquals(46112.0, sheet.getRow(5).getCell(11).getNumericCellValue(), 0.001);
            String joined = dumpColumnC(sheet);
            assertTrue(joined.contains("Калашникова О.В."));
            assertTrue(joined.contains("Павлова Р.С."));
            assertTrue(joined.contains("Агафонова В.Н."));
            assertTrue(joined.contains("Агафонова Е.П."));
            assertTrue(joined.contains("Козлова Т.В."));
            assertTrue(joined.contains("Грачев Н.Ф."));
            assertTrue(!joined.contains("Отказ:"));
            assertTrue(!joined.contains("Ошибка:"));
            int jPos = 0;
            int jNeg = 0;
            for (int r = 6; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) {
                    continue;
                }
                Cell j = row.getCell(9);
                if (j == null || j.getCellType() != CellType.NUMERIC) {
                    continue;
                }
                double v = j.getNumericCellValue();
                if (v < 0) {
                    jNeg++;
                } else if (v > 0) {
                    jPos++;
                }
            }
            assertEquals(0, jNeg, "в эталоне 2_ready отрицательных дней J нет");
            assertEquals(830, jPos, "число строк с J>0 как в 2_ready");
        }
    }

    private static String dumpColumnC(Sheet sheet) {
        StringBuilder sb = new StringBuilder();
        for (int r = 0; r <= sheet.getLastRowNum(); r++) {
            if (sheet.getRow(r) == null || sheet.getRow(r).getCell(2) == null) {
                continue;
            }
            sb.append(sheet.getRow(r).getCell(2).toString()).append('\n');
        }
        return sb.toString();
    }
}
