package com.femsq.web.api.sudz.brief;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.PrintSetup;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.DefaultIndexedColorMap;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Сборка краткого Excel-отчёта из общего свода ДЗ (спека 03-1 §6).
 * Оформление P0+P1 — по эталону {@code 2_ready.xlsx} (ширины, шапка, деньги, ИТОГО/ВСЕГО).
 */
public final class SudzBriefReportBuilder {

    /** Эталонный порядок блоков QI 2026_03. */
    public static final List<String> CANONICAL_ACCOUNTS = List.of(
            "601300", "601750", "601760", "606012", "606022", "682102",
            "761010", "762210", "767401", "767403", "767501", "767502");

    /** Ширины A–L из {@code 2_ready} (Excel width units). */
    static final double[] COLUMN_WIDTHS = {
            11.57, 15.57, 77.0, 24.29, 25.43, 16.43, 15.57, 25.29, 19.86, 15.43, 26.43, 10.71
    };

    private static final Pattern SHEET_ACCOUNT = Pattern.compile("^(\\d{6})(?:\\b|\\s|$).*");

    /** Колонки свода (0-based): A вид; B E C F H I J K L. */
    private static final int SV_DEBT_KIND = 0;
    private static final int SV_ACCOUNT = 1;
    private static final int SV_CTPT_NUM = 4;
    private static final int SV_CTPT_NAME = 2;
    private static final int SV_CONTRACT = 5;
    private static final int SV_DOC = 7;
    private static final int SV_FORMED = 8;
    private static final int SV_DUE = 9;
    private static final int SV_TOTAL = 10;
    private static final int SV_OVERDUE = 11;

    /** В краткий отчёт — только дебиторка ({@code A=D}), как в эталоне {@code 2_ready}. */
    private static final String DEBT_KIND_DEBIT = "D";

    /** Заливка шапки таблицы / ВСЕГО (эталон fill RGB B8CCE4). */
    private static final byte[] FILL_HEADER = {(byte) 0xB8, (byte) 0xCC, (byte) 0xE4};
    /** Заливка строк ИТОГО (светлее шапки; близко к theme-tint эталона). */
    private static final byte[] FILL_SUBTOTAL = {(byte) 0xD6, (byte) 0xE3, (byte) 0xF0};
    private static final byte[] FILL_TOTAL = FILL_HEADER;

    private final DataFormatter formatter = new DataFormatter(Locale.ROOT);

    /**
     * Строит отчёт рядом со сводом.
     *
     * @param svodPath существующий файл свода
     * @param asOf дата отчёта (L6)
     * @param fio порт словаря
     * @return результат с путём и логом
     * @throws IOException IO
     * @throws IllegalStateException нет листов-счетов
     */
    public SudzBriefReportResult build(Path svodPath, LocalDate asOf, FioByDictionary fio)
            throws IOException {
        Objects.requireNonNull(svodPath, "svodPath");
        Objects.requireNonNull(asOf, "asOf");
        Objects.requireNonNull(fio, "fio");
        List<String> log = new ArrayList<>();
        log.add("start: " + svodPath.toAbsolutePath() + " · asOf=" + asOf);

        try (InputStream in = Files.newInputStream(svodPath);
                Workbook source = new XSSFWorkbook(in);
                XSSFWorkbook out = new XSSFWorkbook()) {
            Map<String, Sheet> byAccount = detectAccountSheets(source, log);
            if (byAccount.isEmpty()) {
                throw new IllegalStateException("Нет ни одного листа-счёта в своде");
            }
            List<String> order = orderedAccounts(byAccount.keySet(), log);
            Sheet dest = out.createSheet("краткий");
            applyColumnWidths(dest);
            applyPrintSetup(dest);
            Styles styles = Styles.create(out);

            writeHeader(dest, asOf, styles);
            double excelAsOf = DateUtil.getExcelDate(java.sql.Date.valueOf(asOf));
            Cell l6 = dest.getRow(5).createCell(11);
            l6.setCellValue(excelAsOf);
            l6.setCellStyle(styles.asOfSerial);

            int fioOk = 0;
            int fioSkipWc = 0;
            int fioSkipDict = 0;
            List<Integer> itogoRows = new ArrayList<>();
            int rowIdx = 6; // 0-based; row 7 in Excel = first data

            for (String account : order) {
                Sheet src = byAccount.get(account);
                int blockStart = rowIdx;
                int debtRows = 0;
                for (int r = 1; r <= src.getLastRowNum(); r++) {
                    Row srcRow = src.getRow(r);
                    if (srcRow == null || isEmptyDebt(srcRow)) {
                        continue;
                    }
                    if (!DEBT_KIND_DEBIT.equalsIgnoreCase(cellString(srcRow.getCell(SV_DEBT_KIND)))) {
                        continue;
                    }
                    Double total = numeric(srcRow.getCell(SV_TOTAL));
                    if (total == null) {
                        continue;
                    }
                    Row destRow = dest.createRow(rowIdx++);
                    copyDebtRow(srcRow, destRow, styles, excelAsOf);
                    FioByDictionary.Result fioResult = fio.apply(cellString(destRow.getCell(2)));
                    Cell nameCell = destRow.getCell(2);
                    nameCell.setCellValue(fioResult.text());
                    nameCell.setCellStyle(styles.dataText);
                    if (fioResult.transformed()) {
                        fioOk++;
                    } else if (fioResult.skip() == FioByDictionary.SkipReason.WORD_COUNT) {
                        fioSkipWc++;
                    } else if (fioResult.skip() == FioByDictionary.SkipReason.DICT) {
                        fioSkipDict++;
                    }
                    debtRows++;
                }
                if (debtRows == 0) {
                    log.add("WARN: sheet " + account + ": 0 debt rows");
                    continue;
                }
                int itogoRow = rowIdx;
                Row itogo = dest.createRow(rowIdx++);
                writeItogoRow(itogo, account, blockStart, itogoRow - 1, dest, styles);
                itogoRows.add(itogoRow);
                log.add("sheet " + account + ": " + debtRows + " debt rows");
            }

            if (itogoRows.isEmpty()) {
                throw new IllegalStateException("Нет строк долга ни на одном листе-счёте");
            }

            Row totalRow = dest.createRow(rowIdx);
            double sumH = 0;
            double sumI = 0;
            double sumK = 0;
            for (int ir : itogoRows) {
                Row it = dest.getRow(ir);
                sumH += numericOrZero(it.getCell(7));
                sumI += numericOrZero(it.getCell(8));
                sumK += numericOrZero(it.getCell(10));
            }
            writeTotalRow(totalRow, sumH, sumI, sumK, styles);
            log.add(String.format(Locale.ROOT, "ВСЕГО H=%.2f I=%.2f K=%.2f", sumH, sumI, sumK));
            log.add("fio: transformed=" + fioOk + ", skip_wordcount=" + fioSkipWc
                    + ", skip_dict=" + fioSkipDict);

            Path outPath = outputPathBeside(svodPath);
            try (OutputStream os = Files.newOutputStream(outPath)) {
                out.write(os);
            }
            log.add("done: " + outPath.toAbsolutePath());
            return new SudzBriefReportResult(
                    outPath.toAbsolutePath().normalize().toString(),
                    List.copyOf(log),
                    fioOk,
                    fioSkipWc,
                    fioSkipDict,
                    sumH,
                    sumI,
                    sumK,
                    List.copyOf(order));
        }
    }

    /**
     * Имя выходного файла рядом со сводом.
     *
     * @param svodPath путь свода
     * @return путь {@code {basename}_краткий_отчёт.xlsx}
     */
    public static Path outputPathBeside(Path svodPath) {
        String name = svodPath.getFileName().toString();
        int dot = name.lastIndexOf('.');
        String base = dot > 0 ? name.substring(0, dot) : name;
        return svodPath.resolveSibling(base + "_краткий_отчёт.xlsx");
    }

    private Map<String, Sheet> detectAccountSheets(Workbook source, List<String> log) {
        Map<String, Sheet> map = new LinkedHashMap<>();
        for (int i = 0; i < source.getNumberOfSheets(); i++) {
            Sheet sheet = source.getSheetAt(i);
            String name = sheet.getSheetName() == null ? "" : sheet.getSheetName().trim();
            Matcher m = SHEET_ACCOUNT.matcher(name);
            if (!m.matches()) {
                continue;
            }
            if (name.toLowerCase(Locale.ROOT).contains("нет")) {
                log.add("skip sheet " + name);
                continue;
            }
            String code = m.group(1);
            map.putIfAbsent(code, sheet);
        }
        return map;
    }

    private List<String> orderedAccounts(Set<String> present, List<String> log) {
        List<String> order = new ArrayList<>();
        Set<String> left = new LinkedHashSet<>(present);
        for (String code : CANONICAL_ACCOUNTS) {
            if (left.remove(code)) {
                order.add(code);
            } else {
                log.add("WARN: missing sheet " + code);
            }
        }
        for (String extra : left) {
            order.add(extra);
            log.add("WARN: unknown sheet " + extra);
        }
        return order;
    }

    private void writeHeader(Sheet dest, LocalDate asOf, Styles styles) {
        Row row1 = dest.createRow(0);
        for (int c = 0; c < 11; c++) {
            Cell cell = row1.createCell(c);
            cell.setCellStyle(styles.titlePlain);
        }
        Cell appendix = row1.createCell(10);
        appendix.setCellValue("Приложение № 1 к письму от ____________ № __________");
        appendix.setCellStyle(styles.appendix);

        dest.createRow(1);

        Row row3 = dest.createRow(2);
        for (int c = 0; c < 11; c++) {
            Cell cell = row3.createCell(c);
            cell.setCellStyle(styles.titleMain);
        }
        row3.getCell(0).setCellValue("Отчет по дебиторской задолженности");
        dest.addMergedRegion(new CellRangeAddress(2, 2, 0, 10));

        Row row4 = dest.createRow(3);
        for (int c = 0; c < 11; c++) {
            Cell cell = row4.createCell(c);
            cell.setCellStyle(styles.titlePlain);
        }
        String day = String.valueOf(asOf.getDayOfMonth());
        String monthYear = asOf.format(DateTimeFormatter.ofPattern("MMMM yyyy 'г.'",
                Locale.forLanguageTag("ru")));
        row4.getCell(0).setCellValue("Отчет на \"" + day + "\" " + monthYear);

        dest.createRow(4);

        Row headers = dest.createRow(5);
        headers.setHeightInPoints(75f);
        String[] titles = {
            "Счет Главной книги",
            "№ контрагента",
            "Контрагент",
            "Договор",
            "Реквизиты документа основания (счет-фактура, N и дата первичного документа и т.п.)",
            "Дата образования",
            "Срок погашения",
            "Всего сумма задолженности в рублях",
            "Просроченная задолженность в рублях",
            "Количество дней просрочки",
            "Непросроченная задолженность в рублях"
        };
        for (int c = 0; c < titles.length; c++) {
            Cell cell = headers.createCell(c);
            cell.setCellValue(titles[c]);
            cell.setCellStyle(headerStyleForColumn(c, styles));
        }
    }

    private static CellStyle headerStyleForColumn(int col, Styles styles) {
        if (col == 0) {
            return styles.headerFirst;
        }
        if (col == 10) {
            return styles.headerLast;
        }
        return styles.headerMid;
    }

    private void copyDebtRow(Row src, Row dest, Styles styles, double excelAsOf) {
        setStyledString(dest, 0, cellString(src.getCell(SV_ACCOUNT)), styles.dataText);
        setStyledString(dest, 1, cellString(src.getCell(SV_CTPT_NUM)), styles.dataTextLeft);
        setStyledString(dest, 2, cellString(src.getCell(SV_CTPT_NAME)), styles.dataText);
        setStyledString(dest, 3, cellString(src.getCell(SV_CONTRACT)), styles.dataText);
        setStyledString(dest, 4, cellString(src.getCell(SV_DOC)), styles.dataText);
        copyDateOrBlank(src.getCell(SV_FORMED), dest.createCell(5), styles.dataDate);
        Cell dueDest = dest.createCell(6);
        copyDateOrBlank(src.getCell(SV_DUE), dueDest, styles.dataDate);
        double h = nz(numeric(src.getCell(SV_TOTAL)));
        double i = nz(numeric(src.getCell(SV_OVERDUE)));
        Cell hCell = dest.createCell(7);
        hCell.setCellValue(h);
        hCell.setCellStyle(styles.dataMoney);
        // Как 2_ready: I и J только при просрочке; иначе ячейки пустые (не 0 и не отрицательные дни).
        if (i > 1e-9) {
            Cell iCell = dest.createCell(8);
            iCell.setCellValue(i);
            iCell.setCellStyle(styles.dataMoney);
        }
        double dueSerial = dueDest.getCellType() == CellType.NUMERIC
                ? dueDest.getNumericCellValue()
                : excelAsOf;
        double days = excelAsOf - dueSerial;
        if (days > 0) {
            Cell jCell = dest.createCell(9);
            jCell.setCellValue(days);
            jCell.setCellStyle(styles.dataDays);
        }
        Cell kCell = dest.createCell(10);
        kCell.setCellValue(h - i);
        kCell.setCellStyle(styles.dataMoney);
    }

    private void writeItogoRow(
            Row itogo,
            String account,
            int firstDataRow,
            int lastDataRow,
            Sheet dest,
            Styles styles
    ) {
        double h = 0;
        double i = 0;
        double k = 0;
        for (int r = firstDataRow; r <= lastDataRow; r++) {
            Row row = dest.getRow(r);
            h += numericOrZero(row.getCell(7));
            i += numericOrZero(row.getCell(8));
            k += numericOrZero(row.getCell(10));
        }
        for (int c = 0; c < 11; c++) {
            Cell cell = itogo.createCell(c);
            cell.setCellStyle(styles.itogoText);
        }
        itogo.getCell(0).setCellValue(account);
        itogo.getCell(2).setCellValue("ИТОГО по Счёту " + account + ":");
        Cell hCell = itogo.getCell(7);
        hCell.setCellValue(h);
        hCell.setCellStyle(styles.itogoMoney);
        if (i > 1e-9) {
            Cell iCell = itogo.getCell(8);
            iCell.setCellValue(i);
            iCell.setCellStyle(styles.itogoMoney);
        }
        Cell kCell = itogo.getCell(10);
        kCell.setCellValue(k);
        kCell.setCellStyle(styles.itogoMoney);
    }

    private void writeTotalRow(Row totalRow, double sumH, double sumI, double sumK, Styles styles) {
        for (int c = 0; c < 11; c++) {
            Cell cell = totalRow.createCell(c);
            cell.setCellStyle(styles.totalText);
        }
        totalRow.getCell(2).setCellValue("ВСЕГО дебиторская задолженность:");
        Cell hCell = totalRow.getCell(7);
        hCell.setCellValue(sumH);
        hCell.setCellStyle(styles.totalMoney);
        if (sumI > 1e-9) {
            Cell iCell = totalRow.getCell(8);
            iCell.setCellValue(sumI);
            iCell.setCellStyle(styles.totalMoney);
        }
        Cell kCell = totalRow.getCell(10);
        kCell.setCellValue(sumK);
        kCell.setCellStyle(styles.totalMoney);
        totalRow.setHeightInPoints(18.75f);
    }

    private static double numericOrZero(Cell cell) {
        if (cell == null || cell.getCellType() != CellType.NUMERIC) {
            return 0.0;
        }
        return cell.getNumericCellValue();
    }

    private static void applyColumnWidths(Sheet dest) {
        for (int i = 0; i < COLUMN_WIDTHS.length; i++) {
            dest.setColumnWidth(i, (int) Math.round(COLUMN_WIDTHS[i] * 256));
        }
    }

    private static void applyPrintSetup(Sheet dest) {
        dest.setFitToPage(true);
        PrintSetup ps = dest.getPrintSetup();
        ps.setPaperSize(PrintSetup.A4_PAPERSIZE);
        ps.setFitWidth((short) 1);
        ps.setFitHeight((short) 0);
        dest.setDisplayGridlines(false);
        dest.setPrintGridlines(false);
    }

    private boolean isEmptyDebt(Row row) {
        String account = cellString(row.getCell(SV_ACCOUNT));
        String name = cellString(row.getCell(SV_CTPT_NAME));
        Double total = numeric(row.getCell(SV_TOTAL));
        return (account == null || account.isBlank())
                && (name == null || name.isBlank())
                && total == null;
    }

    private static void setStyledString(Row row, int col, String value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value == null ? "" : value);
        cell.setCellStyle(style);
    }

    private void copyDateOrBlank(Cell src, Cell dest, CellStyle dateStyle) {
        if (src == null) {
            dest.setBlank();
            dest.setCellStyle(dateStyle);
            return;
        }
        if (src.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(src)) {
            dest.setCellValue(src.getNumericCellValue());
            dest.setCellStyle(dateStyle);
            return;
        }
        if (src.getCellType() == CellType.NUMERIC) {
            dest.setCellValue(src.getNumericCellValue());
            dest.setCellStyle(dateStyle);
            return;
        }
        String text = formatter.formatCellValue(src).trim();
        if (text.isEmpty()) {
            dest.setBlank();
            dest.setCellStyle(dateStyle);
            return;
        }
        dest.setCellValue(text);
        dest.setCellStyle(dateStyle);
    }

    private Double numeric(Cell cell) {
        if (cell == null) {
            return null;
        }
        return switch (cell.getCellType()) {
            case NUMERIC -> cell.getNumericCellValue();
            case STRING -> {
                String t = cell.getStringCellValue().trim().replace('\u00a0', ' ')
                        .replace(" ", "").replace(',', '.');
                if (t.isEmpty()) {
                    yield null;
                }
                try {
                    yield Double.parseDouble(t);
                } catch (NumberFormatException ex) {
                    yield null;
                }
            }
            case FORMULA -> {
                try {
                    yield cell.getNumericCellValue();
                } catch (Exception ex) {
                    yield null;
                }
            }
            default -> null;
        };
    }

    private String cellString(Cell cell) {
        if (cell == null) {
            return "";
        }
        return formatter.formatCellValue(cell).trim();
    }

    private static double nz(Double v) {
        return v == null ? 0.0 : v;
    }

    /**
     * Набор стилей отчёта (один на книгу).
     */
    private static final class Styles {
        final CellStyle appendix;
        final CellStyle titleMain;
        final CellStyle titlePlain;
        final CellStyle headerFirst;
        final CellStyle headerMid;
        final CellStyle headerLast;
        final CellStyle asOfSerial;
        final CellStyle dataText;
        final CellStyle dataTextLeft;
        final CellStyle dataDate;
        final CellStyle dataMoney;
        final CellStyle dataDays;
        final CellStyle itogoText;
        final CellStyle itogoMoney;
        final CellStyle totalText;
        final CellStyle totalMoney;

        private Styles(
                CellStyle appendix,
                CellStyle titleMain,
                CellStyle titlePlain,
                CellStyle headerFirst,
                CellStyle headerMid,
                CellStyle headerLast,
                CellStyle asOfSerial,
                CellStyle dataText,
                CellStyle dataTextLeft,
                CellStyle dataDate,
                CellStyle dataMoney,
                CellStyle dataDays,
                CellStyle itogoText,
                CellStyle itogoMoney,
                CellStyle totalText,
                CellStyle totalMoney
        ) {
            this.appendix = appendix;
            this.titleMain = titleMain;
            this.titlePlain = titlePlain;
            this.headerFirst = headerFirst;
            this.headerMid = headerMid;
            this.headerLast = headerLast;
            this.asOfSerial = asOfSerial;
            this.dataText = dataText;
            this.dataTextLeft = dataTextLeft;
            this.dataDate = dataDate;
            this.dataMoney = dataMoney;
            this.dataDays = dataDays;
            this.itogoText = itogoText;
            this.itogoMoney = itogoMoney;
            this.totalText = totalText;
            this.totalMoney = totalMoney;
        }

        static Styles create(XSSFWorkbook wb) {
            CreationHelper helper = wb.getCreationHelper();
            short moneyFmt = helper.createDataFormat().getFormat("#,##0.00");
            short dateFmt = helper.createDataFormat().getFormat("dd.mm.yyyy");
            short intFmt = helper.createDataFormat().getFormat("0");

            Font tnr12 = font(wb, "Times New Roman", 12, false);
            Font tnr12b = font(wb, "Times New Roman", 12, true);
            Font tnr14b = font(wb, "Times New Roman", 14, true);
            Font arial10 = font(wb, "Arial", 10, false);

            CellStyle appendix = wb.createCellStyle();
            appendix.setFont(tnr12);
            appendix.setAlignment(HorizontalAlignment.RIGHT);
            appendix.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle titleMain = wb.createCellStyle();
            titleMain.setFont(tnr14b);
            titleMain.setAlignment(HorizontalAlignment.CENTER);
            titleMain.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle titlePlain = wb.createCellStyle();
            titlePlain.setFont(tnr12);
            titlePlain.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle headerFirst = headerStyle(wb, tnr12b, FILL_HEADER,
                    BorderStyle.MEDIUM, BorderStyle.THIN, BorderStyle.MEDIUM, BorderStyle.NONE);
            CellStyle headerMid = headerStyle(wb, tnr12b, FILL_HEADER,
                    BorderStyle.THIN, BorderStyle.THIN, BorderStyle.MEDIUM, BorderStyle.NONE);
            CellStyle headerLast = headerStyle(wb, tnr12b, FILL_HEADER,
                    BorderStyle.THIN, BorderStyle.MEDIUM, BorderStyle.MEDIUM, BorderStyle.NONE);

            CellStyle asOfSerial = wb.createCellStyle();
            asOfSerial.setDataFormat(dateFmt);

            CellStyle dataText = wb.createCellStyle();
            dataText.setFont(arial10);
            dataText.setVerticalAlignment(VerticalAlignment.TOP);
            dataText.setWrapText(true);

            CellStyle dataTextLeft = wb.createCellStyle();
            dataTextLeft.cloneStyleFrom(dataText);
            dataTextLeft.setAlignment(HorizontalAlignment.LEFT);

            CellStyle dataDate = wb.createCellStyle();
            dataDate.setFont(arial10);
            dataDate.setDataFormat(dateFmt);
            dataDate.setAlignment(HorizontalAlignment.RIGHT);
            dataDate.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle dataMoney = wb.createCellStyle();
            dataMoney.setFont(arial10);
            dataMoney.setDataFormat(moneyFmt);
            dataMoney.setAlignment(HorizontalAlignment.RIGHT);
            dataMoney.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle dataDays = wb.createCellStyle();
            dataDays.setFont(arial10);
            dataDays.setDataFormat(intFmt);
            dataDays.setAlignment(HorizontalAlignment.RIGHT);
            dataDays.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle itogoText = bandStyle(wb, tnr12b, FILL_SUBTOTAL, false);
            CellStyle itogoMoney = bandStyle(wb, tnr12b, FILL_SUBTOTAL, true);
            itogoMoney.setDataFormat(moneyFmt);
            itogoMoney.setAlignment(HorizontalAlignment.RIGHT);

            CellStyle totalText = bandStyle(wb, tnr12b, FILL_TOTAL, false);
            totalText.setFont(tnr14b);
            CellStyle totalMoney = bandStyle(wb, tnr12b, FILL_TOTAL, true);
            totalMoney.setDataFormat(moneyFmt);
            totalMoney.setAlignment(HorizontalAlignment.RIGHT);

            return new Styles(
                    appendix, titleMain, titlePlain,
                    headerFirst, headerMid, headerLast, asOfSerial,
                    dataText, dataTextLeft, dataDate, dataMoney, dataDays,
                    itogoText, itogoMoney, totalText, totalMoney);
        }

        private static Font font(Workbook wb, String name, int size, boolean bold) {
            Font font = wb.createFont();
            font.setFontName(name);
            font.setFontHeightInPoints((short) size);
            font.setBold(bold);
            return font;
        }

        private static CellStyle headerStyle(
                XSSFWorkbook wb,
                Font font,
                byte[] rgb,
                BorderStyle left,
                BorderStyle right,
                BorderStyle top,
                BorderStyle bottom
        ) {
            XSSFCellStyle style = wb.createCellStyle();
            style.setFont(font);
            style.setAlignment(HorizontalAlignment.CENTER);
            style.setVerticalAlignment(VerticalAlignment.CENTER);
            style.setWrapText(true);
            style.setBorderLeft(left);
            style.setBorderRight(right);
            style.setBorderTop(top);
            style.setBorderBottom(bottom);
            applyFill(style, rgb);
            return style;
        }

        private static CellStyle bandStyle(XSSFWorkbook wb, Font font, byte[] rgb, boolean money) {
            XSSFCellStyle style = wb.createCellStyle();
            style.setFont(font);
            style.setVerticalAlignment(VerticalAlignment.TOP);
            style.setWrapText(true);
            style.setBorderLeft(BorderStyle.THIN);
            style.setBorderRight(BorderStyle.THIN);
            style.setBorderTop(BorderStyle.THIN);
            style.setBorderBottom(BorderStyle.THIN);
            if (!money) {
                style.setAlignment(HorizontalAlignment.LEFT);
            }
            applyFill(style, rgb);
            return style;
        }

        private static void applyFill(XSSFCellStyle style, byte[] rgb) {
            XSSFColor color = new XSSFColor(rgb, new DefaultIndexedColorMap());
            style.setFillForegroundColor(color);
            style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        }
    }
}
