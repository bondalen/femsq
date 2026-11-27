package com.femsq.web.ipg.excel;

import com.femsq.database.model.ImpIpgMonfParseRow;
import com.femsq.database.util.FemsqMoney;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Парсер помесячного Excel агента по якорям Access LdM (C2 §6.5).
 *
 * <p>Якоря: колонка «Код…», подстрока {@code limColumn}; маска кода {@code ???-???????};
 * суммы от колонки лимита со смещением {@code sumFirst} (16 Q+M или 12 M).
 */
@Component
public class IpgMonfExcelParser {

    /** Access {@code ???-???????}: 3 символа + 7 цифр (часто {@code NNN-NNNNNNN}). */
    private static final Pattern CODE_MASK = Pattern.compile(
            "^\\d{3}-\\d{7}$");

    private static final String[] CODE_ANCHORS = {
            "Код стройки",
            "Код объекта/стройки",
            "Код объекта (ИУС)",
            "Код ИП",
            "Код"
    };

    private final DataFormatter formatter = new DataFormatter(Locale.ROOT);

    /**
     * Разбор файла по конфигу Monf.
     *
     * @param filePath     путь xlsx
     * @param sheetHint    имя листа или null/blank → авто
     * @param limColumn    подстрока заголовка колонки лимита (обязательна)
     * @param quarter      true = 16 чисел Q+M
     * @param sumFirst     смещение первой суммы от колонки лимита (≥0)
     * @param costItsNames имена направлений затрат (точный match Access) — отсев
     */
    public ParseOutcome parse(
            Path filePath,
            String sheetHint,
            String limColumn,
            boolean quarter,
            int sumFirst,
            Set<String> costItsNames) {
        Objects.requireNonNull(filePath, "filePath");
        if (limColumn == null || limColumn.isBlank()) {
            throw new IpgMonfExcelException("Не задан якорь колонки лимита (limColumn)");
        }
        if (sumFirst < 0) {
            throw new IpgMonfExcelException("sumFirst не может быть отрицательным: " + sumFirst);
        }
        if (!Files.isRegularFile(filePath)) {
            throw new IpgMonfExcelException("Файл Excel не найден: " + filePath);
        }
        Set<String> costNames = costItsNames != null ? costItsNames : Set.of();
        double previousRatio = ZipSecureFile.getMinInflateRatio();
        ZipSecureFile.setMinInflateRatio(0.0);
        try (InputStream inputStream = Files.newInputStream(filePath);
             Workbook workbook = WorkbookFactory.create(inputStream)) {
            Sheet sheet = selectSheet(workbook, sheetHint);
            return parseSheet(sheet, limColumn.trim(), quarter, sumFirst, costNames);
        } catch (IpgMonfExcelException exception) {
            throw exception;
        } catch (IOException exception) {
            throw new IpgMonfExcelException("Не удалось прочитать Excel: " + filePath, exception);
        } catch (Exception exception) {
            throw new IpgMonfExcelException(
                    "Ошибка разбора Monf Excel: " + filePath + " — " + exception.getMessage(),
                    exception);
        } finally {
            ZipSecureFile.setMinInflateRatio(previousRatio);
        }
    }

    private ParseOutcome parseSheet(
            Sheet sheet,
            String limColumn,
            boolean quarter,
            int sumFirst,
            Set<String> costNames) {
        int codeCol = findCodeColumn(sheet);
        int limCol = findLimColumn(sheet, limColumn);
        if (codeCol < 0) {
            throw new IpgMonfExcelException(
                    "На листе «" + sheet.getSheetName() + "» не найден якорь колонки кода");
        }
        if (limCol < 0) {
            throw new IpgMonfExcelException(
                    "На листе «" + sheet.getSheetName()
                            + "» не найден якорь лимита «" + limColumn + "»");
        }
        int ddOffset = limCol - codeCol;
        int firstSumOffsetFromCode = ddOffset + sumFirst;

        List<ImpIpgMonfParseRow> loaded = new ArrayList<>();
        int codeHits = 0;
        int skipped = 0;
        int lastRow = sheet.getLastRowNum();
        for (int r = 0; r <= lastRow; r++) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            String code = cellText(row.getCell(codeCol));
            if (code == null || !CODE_MASK.matcher(code.trim()).matches()) {
                continue;
            }
            codeHits++;
            String cstCode = code.trim();
            String name = cellText(row.getCell(codeCol + 1));
            BigDecimal limYear = cellMoney(row.getCell(limCol));
            if (limYear == null || limYear.compareTo(BigDecimal.ZERO) == 0) {
                skipped++;
                continue;
            }
            if (name != null && costNames.contains(name.trim())) {
                skipped++;
                continue;
            }
            List<BigDecimal> quarters = new ArrayList<>(4);
            List<BigDecimal> months = new ArrayList<>(12);
            if (quarter) {
                // Access: Q1,M1,M2,M3, Q2,M4… — 16 клеток от OffsetInt
                for (int i = 0; i < 16; i++) {
                    BigDecimal v = cellMoney(row.getCell(codeCol + firstSumOffsetFromCode + i));
                    if (i % 4 == 0) {
                        quarters.add(v);
                    } else {
                        months.add(v);
                    }
                }
            } else {
                for (int i = 0; i < 12; i++) {
                    months.add(cellMoney(row.getCell(codeCol + firstSumOffsetFromCode + i)));
                }
            }
            while (months.size() < 12) {
                months.add(null);
            }
            while (quarter && quarters.size() < 4) {
                quarters.add(null);
            }
            loaded.add(new ImpIpgMonfParseRow(
                    r + 1,
                    cstCode,
                    name,
                    FemsqMoney.roundMln(limYear),
                    List.copyOf(quarters),
                    List.copyOf(months),
                    false,
                    null));
        }
        return new ParseOutcome(
                sheet.getSheetName(),
                codeCol + 1,
                limCol + 1,
                codeHits,
                skipped,
                List.copyOf(loaded));
    }

    private Sheet selectSheet(Workbook workbook, String sheetHint) {
        if (sheetHint != null && !sheetHint.isBlank()) {
            Sheet sheet = workbook.getSheet(sheetHint.trim());
            if (sheet == null) {
                throw new IpgMonfExcelException("Лист не найден: «" + sheetHint + "»");
            }
            return sheet;
        }
        Sheet best = null;
        for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
            Sheet sheet = workbook.getSheetAt(i);
            if (findCodeColumn(sheet) >= 0) {
                best = sheet;
                // prefer name containing sql (агентские выгрузки)
                String name = sheet.getSheetName().toLowerCase(Locale.ROOT);
                if (name.contains("sql") || name.contains("план")) {
                    return sheet;
                }
            }
        }
        if (best != null) {
            return best;
        }
        if (workbook.getNumberOfSheets() == 0) {
            throw new IpgMonfExcelException("В книге нет листов");
        }
        return workbook.getSheetAt(0);
    }

    private int findCodeColumn(Sheet sheet) {
        int scanRows = Math.min(sheet.getLastRowNum(), 30);
        for (String anchor : CODE_ANCHORS) {
            int col = findHeaderContaining(sheet, scanRows, anchor, "Код".equals(anchor));
            if (col >= 0) {
                return col;
            }
        }
        return -1;
    }

    private int findLimColumn(Sheet sheet, String limColumn) {
        int scanRows = Math.min(sheet.getLastRowNum(), 30);
        return findHeaderContaining(sheet, scanRows, limColumn, false);
    }

    /**
     * Ищет первую ячейку в первых {@code scanRows}, содержащую текст (или exact для whole).
     *
     * @return 0-based column или -1
     */
    private int findHeaderContaining(Sheet sheet, int scanRows, String needle, boolean whole) {
        String target = needle.toLowerCase(Locale.ROOT);
        for (int r = 0; r <= scanRows; r++) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            short last = row.getLastCellNum();
            if (last < 0) {
                continue;
            }
            for (int c = 0; c < last; c++) {
                String text = cellText(row.getCell(c));
                if (text == null) {
                    continue;
                }
                String norm = text.replace('\n', ' ').trim().toLowerCase(Locale.ROOT);
                if (whole) {
                    if (norm.equals(target)) {
                        return c;
                    }
                } else if (norm.contains(target)) {
                    return c;
                }
            }
        }
        return -1;
    }

    private String cellText(Cell cell) {
        if (cell == null) {
            return null;
        }
        String text = formatter.formatCellValue(cell);
        if (text == null || text.isBlank()) {
            return null;
        }
        return text.trim();
    }

    private BigDecimal cellMoney(Cell cell) {
        if (cell == null) {
            return null;
        }
        CellType type = cell.getCellType();
        if (type == CellType.FORMULA) {
            type = cell.getCachedFormulaResultType();
        }
        if (type == CellType.NUMERIC) {
            return FemsqMoney.roundMln(BigDecimal.valueOf(cell.getNumericCellValue()));
        }
        if (type == CellType.STRING) {
            String raw = cell.getStringCellValue();
            if (raw == null || raw.isBlank()) {
                return null;
            }
            String normalized = raw.trim().replace('\u00a0', ' ').replace(" ", "").replace(',', '.');
            try {
                return FemsqMoney.roundMln(new BigDecimal(normalized));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    /**
     * Исход разбора одного листа.
     */
    public record ParseOutcome(
            String sheetName,
            int codeColumn1Based,
            int limColumn1Based,
            int codeHits,
            int skippedCount,
            List<ImpIpgMonfParseRow> rows) {

        public ParseOutcome {
            rows = rows == null ? List.of() : List.copyOf(rows);
        }

        public int loadedCount() {
            return rows.size();
        }

        public List<ImpIpgMonfParseRow> rowsView() {
            return Collections.unmodifiableList(rows);
        }
    }
}
