package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzSvodAccount;
import com.femsq.database.model.sudz.SudzSvodResult;
import com.femsq.database.model.sudz.SudzSvodTotal;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.ss.util.CellReference;
import org.apache.poi.xssf.usermodel.DefaultIndexedColorMap;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Excel итоговых документов СУДЗ: D644 (построчно) и годовой свод по счетам ГК.
 *
 * <p>D644 — по эталону {@code excel/2026_03/debit/Приложение 1. Сведения о ходе…xlsx}
 * (лист {@code ags_Yr_DbtChangesRsltD644_*}): 18 колонок, шапка письма, жёлтый {@code SUM}
 * под каждым счётом ГК.
 */
public final class SudzD644ExcelExporter {

    private static final DateTimeFormatter DD_MM_YYYY = DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final String MONEY_FORMAT =
            "_-* #,##0.00\\ [$₽-419]_-;\\-* #,##0.00\\ [$₽-419]_-;_-* \"-\"??\\ [$₽-419]_-;_-@_-";
    private static final String PCT_FORMAT = "0.00%";
    private static final String DATE_FORMAT = "mm-dd-yy";

    /** Header fill ≈ theme accent tint 0.8 (светло-голубой эталона). */
    private static final String FILL_HEADER = "BDD7EE";
    /** Базовые суммы/сроки (J–L в эталоне 26-05 — другой theme). */
    private static final String FILL_HEADER_BASE = "D9E1F2";
    private static final String FILL_TITLE = "FFFFFF";
    private static final String FILL_TOTAL_SVOD = "D9D9D9";
    private static final String FILL_MONEY_HL = "FFFF99";

    /** Ширины колонок A–R из эталона Приложение 1 (2026_03). */
    private static final double[] COL_WIDTHS = {
            9.7109375, 16.28515625, 11.7109375, 13.0, 27.7109375, 23.0, 11.0, 15.140625,
            11.0, 12.42578125, 17.140625, 17.7109375, 11.7109375, 15.85546875, 17.85546875,
            13.85546875, 24.5703125, 106.28515625
    };

    private static final int COL_ACCOUNT = 0;
    private static final int COL_TTL_BASE = 10;
    private static final int COL_OVERD_BASE = 11;
    private static final int COL_OVERD_CURR = 13;
    private static final int COL_REPAID = 14;
    private static final int COL_COUNT = 18;

    private SudzD644ExcelExporter() {
    }

    /**
     * Построчный итоговый документ D644 (формат Приложения).
     *
     * @param rows строки {@code Yr_DbtChangesD644}
     * @return байты .xlsx
     * @throws IOException ошибка записи
     */
    public static byte[] exportD644(List<SudzD644Row> rows) throws IOException {
        LocalDate baseDate = rows.isEmpty() ? null : rows.get(0).baseUplDate();
        LocalDate currDate = rows.isEmpty() ? null : rows.get(0).currUplDate();
        String baseAsOf = statusAsOfLabel(baseDate, true);
        String currAsOf = statusAsOfLabel(currDate, false);
        String[] headers = {
                "Счёт Главной книги",
                "Агент",
                "№ контрагента",
                "ИНН контрагента",
                "Контрагент",
                "Договор",
                "Дата договора",
                "Реквизиты документа основания \n(счет-фактура, N и дата первичного документа и т.п.)",
                "Дата образования",
                "Срок погашения \n(по состоянию на " + baseAsOf + ")",
                "Всего сумма задолженности в рублях \n(по состоянию на " + baseAsOf + ")",
                "Просроченная задолженность в рублях \n(по состоянию на " + baseAsOf + ")",
                "Срок погашения \n(по состоянию на " + currAsOf + ")",
                "Просроченная задолженность в рублях \n(по состоянию на " + currAsOf + ")",
                "Погашено просроченной задолженности с начала года в рублях \n(по состоянию на "
                        + currAsOf + ")",
                "Код стройки",
                "Наименование стройки",
                "Комментарий Филиала 644"
        };

        List<SudzD644Row> sorted = new ArrayList<>(rows);
        sorted.sort(Comparator
                .comparing((SudzD644Row r) -> r.accountNum() == null ? Integer.MAX_VALUE : r.accountNum())
                .thenComparing(r -> Objects.toString(r.counterpart(), ""))
                .thenComparing(SudzD644Row::dbtKey));

        Map<Integer, List<SudzD644Row>> byAccount = new LinkedHashMap<>();
        for (SudzD644Row row : sorted) {
            int key = row.accountNum() == null ? -1 : row.accountNum();
            byAccount.computeIfAbsent(key, ignored -> new ArrayList<>()).add(row);
        }

        String sheetName = "ags_Yr_DbtChangesRsltD644";
        if (currDate != null) {
            sheetName = "ags_Yr_DbtChangesRsltD644_"
                    + String.format("%02d-%02d", currDate.getYear() % 100, currDate.getMonthValue());
            if (sheetName.length() > 31) {
                sheetName = sheetName.substring(0, 31);
            }
        }

        try (XSSFWorkbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet(sheetName);
            Styles styles = new Styles(workbook);

            Row row1 = sheet.createRow(0);
            for (int c = 0; c < COL_COUNT; c++) {
                Cell empty = row1.createCell(c);
                empty.setCellStyle(styles.title());
            }
            Cell appendix = row1.getCell(COL_COUNT - 1);
            appendix.setCellValue("Приложение 1 к письму ______________________________");
            appendix.setCellStyle(styles.appendix());

            Row row2 = sheet.createRow(1);
            Cell title = row2.createCell(0);
            title.setCellValue(
                    "Сведения о ходе работы по снижению просроченной дебиторской задолженности "
                            + "по балансовым счетам 606012, 762210, 767502"
            );
            title.setCellStyle(styles.titleBold());
            for (int c = 1; c < COL_COUNT; c++) {
                row2.createCell(c).setCellStyle(styles.title());
            }
            sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, COL_COUNT - 1));

            sheet.createRow(2);

            Row headerRow = sheet.createRow(3);
            headerRow.setHeightInPoints(72f);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                boolean baseBand = i >= 9 && i <= 11;
                cell.setCellStyle(baseBand ? styles.headerBase() : styles.header());
            }

            int excelRowIdx = 4; // 0-based; first data = Excel row 5
            for (Map.Entry<Integer, List<SudzD644Row>> entry : byAccount.entrySet()) {
                List<SudzD644Row> group = entry.getValue();
                int firstDataExcelRow = excelRowIdx + 1; // 1-based for formulas
                for (SudzD644Row row : group) {
                    Row excelRow = sheet.createRow(excelRowIdx++);
                    writeD644DataRow(excelRow, row, styles);
                }
                int lastDataExcelRow = excelRowIdx; // 1-based inclusive (last written)
                Row totalRow = sheet.createRow(excelRowIdx++);
                writeAccountTotalRow(
                        totalRow,
                        entry.getKey() < 0 ? null : entry.getKey(),
                        firstDataExcelRow,
                        lastDataExcelRow,
                        styles
                );
            }

            int lastRow = Math.max(3, excelRowIdx - 1);
            sheet.setAutoFilter(new CellRangeAddress(3, lastRow, 0, COL_COUNT - 1));
            sheet.createFreezePane(0, 4);

            for (int i = 0; i < COL_WIDTHS.length; i++) {
                sheet.setColumnWidth(i, (int) Math.round(COL_WIDTHS[i] * 256));
            }

            workbook.write(out);
            return out.toByteArray();
        }
    }

    private static void writeD644DataRow(Row excelRow, SudzD644Row row, Styles styles) {
        int c = 0;
        writeNumber(excelRow, c++, row.accountNum(), styles.numberRight());
        writeText(excelRow, c++, row.agent(), styles.text());
        writeNumber(excelRow, c++, row.orgId(), styles.numberRight());
        writeText(excelRow, c++, row.itn(), styles.text());
        writeText(excelRow, c++, row.counterpart(), styles.text());
        writeText(excelRow, c++, row.contract(), styles.text());
        writeDate(excelRow, c++, row.contractDate(), styles.date());
        writeText(excelRow, c++, row.invoice(), styles.text());
        writeDate(excelRow, c++, row.dateStart(), styles.date());
        writeDate(excelRow, c++, row.maturityBase(), styles.date());
        writeMoney(excelRow, c++, row.ttlBase(), styles.money());
        writeMoney(excelRow, c++, row.overdBase(), styles.moneyHighlight());
        writeDate(excelRow, c++, row.maturityCurr(), styles.date());
        writeMoney(excelRow, c++, row.overdCurr(), styles.moneyHighlight());
        writeMoney(excelRow, c++, row.repaid(), styles.money());
        writeText(excelRow, c++, row.cstCode(), styles.text());
        writeText(excelRow, c++, row.cstName(), styles.text());
        writeText(excelRow, c, row.comment644(), styles.text());
        excelRow.setHeightInPoints(rowHeightForComment(row.comment644()));
    }

    /**
     * Высота строки по тексту «Комментарий Филиала 644» (как в эталоне: короткое ~36, длинное — выше).
     *
     * @param comment текст колонки R
     * @return высота в пунктах
     */
    static float rowHeightForComment(String comment) {
        if (comment == null || comment.isBlank()) {
            return 36f;
        }
        // ширина колонки R ≈ 106 символов при Calibri 9
        final int charsPerLine = 95;
        int wrappedLines = 0;
        for (String line : comment.split("\\R", -1)) {
            int len = line.length();
            wrappedLines += Math.max(1, (len + charsPerLine - 1) / charsPerLine);
        }
        float height = 15f * wrappedLines + 6f;
        return Math.min(420f, Math.max(36f, height));
    }

    /**
     * Жёлтая итоговая строка счёта: {@code SUM} по K/L/N/O (как в эталоне).
     */
    private static void writeAccountTotalRow(
            Row totalRow,
            Integer accountNum,
            int firstDataExcelRow1Based,
            int lastDataExcelRow1Based,
            Styles styles
    ) {
        for (int c = 0; c < COL_COUNT; c++) {
            Cell cell = totalRow.createCell(c);
            cell.setCellStyle(styles.accountTotal());
        }
        if (accountNum != null) {
            Cell a = totalRow.getCell(COL_ACCOUNT);
            a.setCellValue(accountNum.doubleValue());
            a.setCellStyle(styles.accountTotal());
        }
        setSumFormula(totalRow, COL_TTL_BASE, firstDataExcelRow1Based, lastDataExcelRow1Based, styles);
        setSumFormula(totalRow, COL_OVERD_BASE, firstDataExcelRow1Based, lastDataExcelRow1Based, styles);
        setSumFormula(totalRow, COL_OVERD_CURR, firstDataExcelRow1Based, lastDataExcelRow1Based, styles);
        setSumFormula(totalRow, COL_REPAID, firstDataExcelRow1Based, lastDataExcelRow1Based, styles);
    }

    private static void setSumFormula(
            Row row,
            int col,
            int firstRow,
            int lastRow,
            Styles styles
    ) {
        Cell cell = row.getCell(col);
        String letter = CellReference.convertNumToColString(col);
        cell.setCellFormula("SUM(" + letter + firstRow + ":" + letter + lastRow + ")");
        cell.setCellStyle(styles.accountTotalMoney());
    }

    /**
     * Годовой свод по субсчетам Д644.
     *
     * @param svod результат {@code Yr_DbtChangesD644Svod}
     * @return байты .xlsx
     * @throws IOException ошибка записи
     */
    public static byte[] exportSvod(SudzSvodResult svod) throws IOException {
        String[] headers = {
                "№ счётов бухгалтерского учета",
                "Наименование счёта",
                "Сумма просроченной ДЗ на начало года",
                "Погашено просроченной ДЗ с начала года",
                "Остаток просроченной ДЗ портфеля",
                "Погашено в %"
        };
        List<SudzSvodAccount> accounts = svod.accounts();
        SudzSvodTotal total = svod.total();

        try (XSSFWorkbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("СВОД по субсчетам Д644");
            Styles styles = new Styles(workbook);

            Row title = sheet.createRow(0);
            Cell t = title.createCell(0);
            t.setCellValue("СВОД по субсчетам Д644 (FEMSQ)");
            t.setCellStyle(styles.titleBold());
            sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, headers.length - 1));

            Row headerRow = sheet.createRow(1);
            headerRow.setHeightInPoints(48f);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(styles.header());
            }

            for (int r = 0; r < accounts.size(); r++) {
                SudzSvodAccount a = accounts.get(r);
                Row excelRow = sheet.createRow(2 + r);
                writeNumber(excelRow, 0, a.accountNum(), styles.text());
                writeText(excelRow, 1, a.accountName(), styles.wrap());
                writeMoney(excelRow, 2, a.overdBase(), styles.money());
                writeMoney(excelRow, 3, a.repaid(), styles.money());
                writeMoney(excelRow, 4, a.overdCurr(), styles.moneyHighlight());
                writePct(excelRow, 5, a.repaidPct(), styles.pct());
            }

            int totalRowIdx = 2 + accounts.size();
            Row totalRow = sheet.createRow(totalRowIdx);
            Cell label = totalRow.createCell(0);
            label.setCellValue("ВСЕГО");
            label.setCellStyle(styles.svodTotal());
            Cell blank = totalRow.createCell(1);
            blank.setCellStyle(styles.svodTotal());
            if (total != null) {
                writeMoney(totalRow, 2, total.overdBase(), styles.svodTotalMoney());
                writeMoney(totalRow, 3, total.repaid(), styles.svodTotalMoney());
                writeMoney(totalRow, 4, total.overdCurr(), styles.svodTotalMoney());
                writePct(totalRow, 5, total.repaidPct(), styles.svodTotalPct());
            } else {
                for (int c = 2; c <= 5; c++) {
                    Cell empty = totalRow.createCell(c);
                    empty.setCellStyle(styles.svodTotal());
                }
            }

            sheet.setAutoFilter(new CellRangeAddress(1, 1, 0, headers.length - 1));
            sheet.createFreezePane(0, 2);
            int[] widths = {14, 56, 18, 18, 18, 12};
            for (int i = 0; i < widths.length; i++) {
                sheet.setColumnWidth(i, widths[i] * 256);
            }

            workbook.write(out);
            return out.toByteArray();
        }
    }

    /**
     * Подпись «по состоянию на …» для шапки колонок.
     *
     * @param date дата среза/базы
     * @param yearStartPortfolio для базы портфеля в январе — 31.12 предыдущего года
     * @return dd.MM.yyyy
     */
    static String statusAsOfLabel(LocalDate date, boolean yearStartPortfolio) {
        if (date == null) {
            return "…";
        }
        if (yearStartPortfolio && date.getMonthValue() == 1) {
            return LocalDate.of(date.getYear() - 1, 12, 31).format(DD_MM_YYYY);
        }
        int q = (date.getMonthValue() - 1) / 3;
        LocalDate end = switch (q) {
            case 0 -> LocalDate.of(date.getYear() - 1, 12, 31);
            case 1 -> LocalDate.of(date.getYear(), 3, 31);
            case 2 -> LocalDate.of(date.getYear(), 6, 30);
            default -> LocalDate.of(date.getYear(), 9, 30);
        };
        return end.format(DD_MM_YYYY);
    }

    private static void writeText(Row row, int col, String value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value);
        }
        cell.setCellStyle(style);
    }

    private static void writeNumber(Row row, int col, Number value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.doubleValue());
        }
        cell.setCellStyle(style);
    }

    private static void writeDate(Row row, int col, LocalDate value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(java.sql.Date.valueOf(value));
        }
        cell.setCellStyle(style);
    }

    private static void writeMoney(Row row, int col, BigDecimal value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.doubleValue());
        }
        cell.setCellStyle(style);
    }

    private static void writePct(Row row, int col, Double value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value / 100.0);
        }
        cell.setCellStyle(style);
    }

    private static final class Styles {
        private final XSSFCellStyle title;
        private final XSSFCellStyle titleBold;
        private final XSSFCellStyle appendix;
        private final XSSFCellStyle header;
        private final XSSFCellStyle headerBase;
        private final XSSFCellStyle text;
        private final XSSFCellStyle wrap;
        private final XSSFCellStyle numberRight;
        private final XSSFCellStyle date;
        private final XSSFCellStyle money;
        private final XSSFCellStyle moneyHighlight;
        private final XSSFCellStyle pct;
        private final XSSFCellStyle accountTotal;
        private final XSSFCellStyle accountTotalMoney;
        private final XSSFCellStyle svodTotal;
        private final XSSFCellStyle svodTotalMoney;
        private final XSSFCellStyle svodTotalPct;

        Styles(XSSFWorkbook workbook) {
            Font titleFont = workbook.createFont();
            titleFont.setFontName("Calibri");
            titleFont.setFontHeightInPoints((short) 11);

            Font titleBoldFont = workbook.createFont();
            titleBoldFont.setFontName("Calibri");
            titleBoldFont.setFontHeightInPoints((short) 11);
            titleBoldFont.setBold(true);

            Font headerFont = workbook.createFont();
            headerFont.setFontName("Calibri");
            headerFont.setFontHeightInPoints((short) 9);
            headerFont.setBold(true);

            Font dataFont = workbook.createFont();
            dataFont.setFontName("Calibri");
            dataFont.setFontHeightInPoints((short) 9);

            Font svodBoldFont = workbook.createFont();
            svodBoldFont.setFontName("Calibri");
            svodBoldFont.setFontHeightInPoints((short) 9);
            svodBoldFont.setBold(true);

            title = workbook.createCellStyle();
            title.setFont(titleFont);
            title.setFillForegroundColor(rgb(FILL_TITLE));
            title.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            title.setVerticalAlignment(VerticalAlignment.CENTER);

            titleBold = workbook.createCellStyle();
            titleBold.cloneStyleFrom(title);
            titleBold.setFont(titleBoldFont);
            titleBold.setAlignment(HorizontalAlignment.CENTER);
            titleBold.setWrapText(true);

            appendix = workbook.createCellStyle();
            appendix.setFont(titleFont);
            appendix.setAlignment(HorizontalAlignment.RIGHT);
            appendix.setVerticalAlignment(VerticalAlignment.CENTER);

            header = workbook.createCellStyle();
            header.setFont(headerFont);
            header.setWrapText(true);
            header.setVerticalAlignment(VerticalAlignment.CENTER);
            header.setAlignment(HorizontalAlignment.CENTER);
            header.setFillForegroundColor(rgb(FILL_HEADER));
            header.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            applyThinBorder(header);

            headerBase = workbook.createCellStyle();
            headerBase.cloneStyleFrom(header);
            headerBase.setFillForegroundColor(rgb(FILL_HEADER_BASE));

            text = workbook.createCellStyle();
            text.setFont(dataFont);
            text.setWrapText(true);
            text.setVerticalAlignment(VerticalAlignment.CENTER);
            text.setAlignment(HorizontalAlignment.LEFT);
            applyThinBorder(text);

            wrap = workbook.createCellStyle();
            wrap.cloneStyleFrom(text);

            numberRight = workbook.createCellStyle();
            numberRight.cloneStyleFrom(text);
            numberRight.setAlignment(HorizontalAlignment.RIGHT);

            date = workbook.createCellStyle();
            date.cloneStyleFrom(numberRight);
            date.setDataFormat(workbook.createDataFormat().getFormat(DATE_FORMAT));

            money = workbook.createCellStyle();
            money.cloneStyleFrom(numberRight);
            money.setDataFormat(workbook.createDataFormat().getFormat(MONEY_FORMAT));

            moneyHighlight = workbook.createCellStyle();
            moneyHighlight.cloneStyleFrom(money);
            moneyHighlight.setFillForegroundColor(rgb(FILL_MONEY_HL));
            moneyHighlight.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            pct = workbook.createCellStyle();
            pct.cloneStyleFrom(numberRight);
            pct.setDataFormat(workbook.createDataFormat().getFormat(PCT_FORMAT));

            accountTotal = workbook.createCellStyle();
            accountTotal.cloneStyleFrom(numberRight);
            accountTotal.setFillForegroundColor(IndexedColors.YELLOW.getIndex());
            accountTotal.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            accountTotalMoney = workbook.createCellStyle();
            accountTotalMoney.cloneStyleFrom(money);
            accountTotalMoney.setFillForegroundColor(IndexedColors.YELLOW.getIndex());
            accountTotalMoney.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            svodTotal = workbook.createCellStyle();
            svodTotal.cloneStyleFrom(text);
            svodTotal.setFont(svodBoldFont);
            svodTotal.setFillForegroundColor(rgb(FILL_TOTAL_SVOD));
            svodTotal.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            svodTotalMoney = workbook.createCellStyle();
            svodTotalMoney.cloneStyleFrom(money);
            svodTotalMoney.setFont(svodBoldFont);
            svodTotalMoney.setFillForegroundColor(rgb(FILL_TOTAL_SVOD));
            svodTotalMoney.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            svodTotalPct = workbook.createCellStyle();
            svodTotalPct.cloneStyleFrom(pct);
            svodTotalPct.setFont(svodBoldFont);
            svodTotalPct.setFillForegroundColor(rgb(FILL_TOTAL_SVOD));
            svodTotalPct.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        }

        CellStyle title() {
            return title;
        }

        CellStyle titleBold() {
            return titleBold;
        }

        CellStyle appendix() {
            return appendix;
        }

        CellStyle header() {
            return header;
        }

        CellStyle headerBase() {
            return headerBase;
        }

        CellStyle text() {
            return text;
        }

        CellStyle wrap() {
            return wrap;
        }

        CellStyle numberRight() {
            return numberRight;
        }

        CellStyle date() {
            return date;
        }

        CellStyle money() {
            return money;
        }

        CellStyle moneyHighlight() {
            return moneyHighlight;
        }

        CellStyle pct() {
            return pct;
        }

        CellStyle accountTotal() {
            return accountTotal;
        }

        CellStyle accountTotalMoney() {
            return accountTotalMoney;
        }

        CellStyle svodTotal() {
            return svodTotal;
        }

        CellStyle svodTotalMoney() {
            return svodTotalMoney;
        }

        CellStyle svodTotalPct() {
            return svodTotalPct;
        }

        private static XSSFColor rgb(String hex) {
            byte[] rgb = new byte[3];
            rgb[0] = (byte) Integer.parseInt(hex.substring(0, 2), 16);
            rgb[1] = (byte) Integer.parseInt(hex.substring(2, 4), 16);
            rgb[2] = (byte) Integer.parseInt(hex.substring(4, 6), 16);
            return new XSSFColor(rgb, new DefaultIndexedColorMap());
        }

        private static void applyThinBorder(CellStyle style) {
            style.setBorderTop(BorderStyle.THIN);
            style.setBorderBottom(BorderStyle.THIN);
            style.setBorderLeft(BorderStyle.THIN);
            style.setBorderRight(BorderStyle.THIN);
        }
    }
}
