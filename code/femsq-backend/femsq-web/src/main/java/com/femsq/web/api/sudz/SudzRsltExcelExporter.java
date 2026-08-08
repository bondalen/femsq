package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzRsltPeriod;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.ss.util.CellReference;
import org.apache.poi.xssf.usermodel.DefaultIndexedColorMap;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Excel Rslt (сбор) в формате эталона Access ({@code ags_Yr_DbtChangesRslt_*}).
 *
 * <p>Шапка: row1 — {@code SUBTOTAL} по суммовым колонкам; row2 — подписи; row3 — техн. имена.
 * Стили (шрифты, заливки, границы, фильтр, freeze) — по
 * {@code excel/2025-12/debit/ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx}.
 *
 * <p>Боковик FEMSQ (08 §3.6.0): {@code dbtKey} + {@code account_num}; СФ/{@code idNum} — в блоках срезов.
 */
public final class SudzRsltExcelExporter {

    private static final DateTimeFormatter ISO = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final String[] ROMAN = {"I", "II", "III", "IV"};
    private static final String[] MONTH_RU = {
            "январь", "февраль", "март", "апрель", "май", "июнь",
            "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь"
    };

    /**
     * Заливки кварталов (row2) из эталона 26-0212 (theme+tint → RGB).
     * Порядок: 0-й срез (база), I, II, III, IV; далее по кругу.
     */
    private static final String[] QUARTER_FILLS = {
            "D9D9D9", // lt1 tint -0.15
            "D6D4CB", // lt2 tint -0.10
            "FFFFCC", // light yellow
            "E6E0EC", // accent4 tint 0.80
            "B7DEE8"  // accent5 tint 0.60
    };

    private static final String FILL_BASE = "FDEADA";       // accent6 tint 0.80 — боковик
    private static final String FILL_INV = "D99694";        // accent2 tint 0.40 — реквизиты СФ
    private static final String FILL_OVERD = "FFFF00";      // просрочка
    private static final String FILL_CURATOR = "D7E4BD";    // accent3 tint 0.60
    private static final String FILL_NEW = "F2DCDB";        // accent2 tint 0.80
    private static final String FILL_TECH = "C0C0C0";       // row3
    private static final String FILL_SUM_TTL = "D9D9D9";    // row1 Ttl/Overd
    private static final String FILL_SUM_POG = "FAC090";    // row1 погашено
    private static final String FONT_SUM_RGB = "C0504D";    // accent2 (красный)

    private static final String MONEY_FORMAT =
            "_-* #,##0.00\\ [$₽-419]_-;\\-* #,##0.00\\ [$₽-419]_-;_-* \"-\"??\\ [$₽-419]_-;_-@_-";

    private SudzRsltExcelExporter() {
    }

    /**
     * Собирает xlsx Rslt сбор ({@code *_new} пустые).
     *
     * @param debts долги со срезами (уже отфильтрованными по asOfUpl)
     * @return байты .xlsx
     * @throws IOException ошибка записи книги
     */
    public static byte[] exportRsltSborn(List<SudzRsltDebt> debts) throws IOException {
        return exportRslt(debts, false);
    }

    /**
     * Собирает xlsx Rslt повтор («старые» + {@code *_new} из {@code yr_CmmGr_New}).
     *
     * @param debts долги со срезами и полями {@code *New}
     * @return байты .xlsx
     * @throws IOException ошибка записи книги
     */
    public static byte[] exportRsltPovtor(List<SudzRsltDebt> debts) throws IOException {
        return exportRslt(debts, true);
    }

    private static byte[] exportRslt(List<SudzRsltDebt> debts, boolean fillNew) throws IOException {
        List<SliceMeta> slices = collectSlices(debts);
        LocalDate newAsOf = slices.isEmpty()
                ? LocalDate.now()
                : slices.get(slices.size() - 1).labelDate();
        String newSuffix = "новый, по состоянию на " + monthYearRu(newAsOf);
        List<ColumnDef> columns = buildColumns(slices, newSuffix);

        try (XSSFWorkbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Rslt");
            Styles styles = new Styles(workbook);

            Row rowSums = sheet.createRow(0);
            Row rowHuman = sheet.createRow(1);
            Row rowTech = sheet.createRow(2);
            rowHuman.setHeightInPoints(96f);

            int lastDataRow = debts.isEmpty() ? 3 : 2 + debts.size();

            for (int i = 0; i < columns.size(); i++) {
                ColumnDef col = columns.get(i);
                writeHeaderCell(rowHuman, i, col.human, styles.human(col.band));
                writeHeaderCell(rowTech, i, col.tech, styles.tech());
                if (col.kind == ColKind.SUM) {
                    Cell sumCell = rowSums.createCell(i);
                    String letter = CellReference.convertNumToColString(i);
                    sumCell.setCellFormula("SUBTOTAL(9," + letter + "4:" + letter + (lastDataRow + 1) + ")");
                    sumCell.setCellStyle(col.band == StyleBand.OVERD
                            ? styles.sumOverd()
                            : (col.tech != null && col.tech.endsWith("_погашено")
                            ? styles.sumPogasheno()
                            : styles.sumTtl()));
                } else {
                    Cell empty = rowSums.createCell(i);
                    empty.setCellStyle(styles.sumEmpty());
                }
            }

            for (int r = 0; r < debts.size(); r++) {
                Row row = sheet.createRow(3 + r);
                writeDebtRow(row, debts.get(r), slices, columns, styles, fillNew);
            }

            if (!columns.isEmpty()) {
                int filterFrom = columns.size() > 1 ? 1 : 0;
                sheet.setAutoFilter(new CellRangeAddress(1, 1, filterFrom, columns.size() - 1));
            }
            sheet.createFreezePane(2, 3);

            applyColumnWidths(sheet, columns);

            workbook.write(out);
            return out.toByteArray();
        }
    }

    private static List<ColumnDef> buildColumns(List<SliceMeta> slices, String newSuffix) {
        List<ColumnDef> cols = new ArrayList<>();
        cols.add(new ColumnDef("", "dbtKey", ColKind.KEY, StyleBand.KEY));
        cols.add(new ColumnDef("Счет Главной книги", "account_num", ColKind.SIDE, StyleBand.BASE));

        for (int s = 0; s < slices.size(); s++) {
            SliceMeta slice = slices.get(s);
            String q = quarterLabel(slice.labelDate());
            String p = slice.uplDate() != null ? slice.uplDate().format(ISO) : "?";
            StyleBand band = StyleBand.quarter(s);
            boolean first = s == 0;

            cols.add(new ColumnDef(
                    "Реквизиты документа основания (счет-фактура, N и дата первичного документа и т.п.)",
                    p + "_invNumEnum", ColKind.TEXT, StyleBand.INV));
            cols.add(new ColumnDef(q + ". № задолженности в СФ", p + "_idNum", ColKind.NUM, band));
            cols.add(new ColumnDef(q + ". Договор", p + "_cnNumEnum", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Дата договора", p + "_csoCnDate", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". № контрагента", p + "_org_id_value_l", ColKind.NUM, band));
            cols.add(new ColumnDef(q + ". ИНН контрагента", p + "_ITN", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Контрагент", p + "_CtptOrg", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Дата погашения", p + "_Maturity", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Общая задолженность", p + "_Ttl", ColKind.SUM, band));
            cols.add(new ColumnDef(
                    q + ". Просроченная задолженность", p + "_Overd", ColKind.SUM, StyleBand.OVERD));
            cols.add(new ColumnDef("", p + "_CstAgPnKey", ColKind.TEXT, StyleBand.KEY));
            cols.add(new ColumnDef(q + ". Код стройки", p + "_CstAgPnCode", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Наименование стройки", p + "_CstAgPnName", ColKind.TEXT, band));
            cols.add(new ColumnDef(q + ". Агент", p + "_AgOrg", ColKind.TEXT, band));
            if (!first) {
                cols.add(new ColumnDef(
                        q + ". Погашенная задолженность", p + "_погашено", ColKind.SUM, band));
            }
        }

        cols.add(new ColumnDef(
                "Куратор от Управления", "Куратор от Управления", ColKind.TEXT, StyleBand.CURATOR));
        cols.add(new ColumnDef(
                "Мероприятия по погашению дебиторской задолженности",
                "Мероприятия по погашению дебиторской задолженности",
                ColKind.TEXT,
                StyleBand.CURATOR));
        cols.add(new ColumnDef("Код стройки", "Код стройки", ColKind.TEXT, StyleBand.CURATOR));
        cols.add(new ColumnDef("Наименование стройки", "Код стройкиN", ColKind.TEXT, StyleBand.CURATOR));
        cols.add(new ColumnDef("Куратор от Управления, " + newSuffix, "cur_new", ColKind.EMPTY, StyleBand.NEW));
        cols.add(new ColumnDef(
                "Мероприятия по погашению дебиторской задолженности, " + newSuffix,
                "mery_new",
                ColKind.EMPTY,
                StyleBand.NEW));
        cols.add(new ColumnDef(
                "Код стройки, кратко, " + newSuffix, "cstAgPn_new", ColKind.EMPTY, StyleBand.NEW));
        return cols;
    }

    private static void writeDebtRow(
            Row row,
            SudzRsltDebt debt,
            List<SliceMeta> slices,
            List<ColumnDef> columns,
            Styles styles,
            boolean fillNew
    ) {
        int c = 0;
        c = writeTyped(row, c, debt.dbtKey(), styles.data());
        c = writeTyped(row, c, debt.accountNum(), styles.data());
        for (int s = 0; s < slices.size(); s++) {
            SliceMeta slice = slices.get(s);
            boolean first = s == 0;
            SudzRsltPeriod period = findPeriod(debt, slice.uplDate());
            int blockCols = first ? 14 : 15;
            if (period == null) {
                for (int k = 0; k < blockCols; k++) {
                    Cell cell = row.createCell(c++);
                    cell.setCellStyle(styles.data());
                }
                continue;
            }
            c = writeTyped(row, c, period.invNumEnum(), styles.data());
            c = writeTyped(row, c, period.idNum(), styles.data());
            c = writeTyped(row, c, period.cnNumEnum(), styles.data());
            c = writeTyped(row, c, period.csoCnDate(), styles.data());
            c = writeTyped(row, c, period.orgIdValueL(), styles.data());
            c = writeTyped(row, c, period.itn(), styles.data());
            c = writeTyped(row, c, period.ctptOrg(), styles.data());
            c = writeTyped(row, c, period.maturity(), styles.data());
            c = writeMoney(row, c, period.ttl(), styles.money());
            c = writeMoney(row, c, period.overd(), styles.money());
            Cell keySpacer = row.createCell(c++);
            keySpacer.setCellStyle(styles.data());
            c = writeTyped(row, c, period.cstAgPnCode(), styles.data());
            c = writeTyped(row, c, period.cstAgPnName(), styles.data());
            c = writeTyped(row, c, period.agOrg(), styles.data());
            if (!first) {
                c = writeMoney(row, c, period.pogasheno(), styles.money());
            }
        }
        c = writeTyped(row, c, debt.curator(), styles.data());
        c = writeTyped(row, c, debt.mery(), styles.data());
        c = writeTyped(row, c, debt.cstCode(), styles.data());
        c = writeTyped(row, c, debt.cstName(), styles.data());
        if (fillNew) {
            c = writeTyped(row, c, debt.curatorNew(), styles.data());
            c = writeTyped(row, c, debt.meryNew(), styles.data());
            c = writeTyped(row, c, debt.cstCodeNew(), styles.data());
        }
        while (c < columns.size()) {
            Cell cell = row.createCell(c++);
            cell.setCellStyle(styles.data());
        }
    }

    private static void applyColumnWidths(Sheet sheet, List<ColumnDef> columns) {
        for (int i = 0; i < columns.size(); i++) {
            ColumnDef col = columns.get(i);
            int width;
            if (col.kind == ColKind.KEY || (col.tech != null && col.tech.endsWith("_CstAgPnKey"))) {
                width = 9;
            } else if (col.tech != null && (col.tech.endsWith("_CtptOrg") || col.tech.endsWith("_CstAgPnName")
                    || "Мероприятия по погашению дебиторской задолженности".equals(col.tech)
                    || "mery_new".equals(col.tech))) {
                width = 28;
            } else if (col.kind == ColKind.SUM) {
                width = 16;
            } else if ("account_num".equals(col.tech)) {
                width = 14;
            } else {
                width = 14;
            }
            sheet.setColumnWidth(i, width * 256);
        }
    }

    private static List<SliceMeta> collectSlices(List<SudzRsltDebt> debts) {
        Map<LocalDate, LocalDate> asOfByUpl = new LinkedHashMap<>();
        for (SudzRsltDebt debt : debts) {
            for (SudzRsltPeriod period : debt.periods()) {
                if (period.uplDate() == null) {
                    continue;
                }
                LocalDate asOf = period.asOf() != null ? period.asOf() : period.uplDate();
                asOfByUpl.merge(period.uplDate(), asOf, (a, b) -> a.isAfter(b) ? a : b);
            }
        }
        List<SliceMeta> slices = new ArrayList<>();
        for (Map.Entry<LocalDate, LocalDate> e : asOfByUpl.entrySet()) {
            slices.add(new SliceMeta(e.getKey(), e.getValue()));
        }
        return slices;
    }

    /**
     * Подпись квартала по дате состояния (как в эталоне: «2025. IV-й квартал»).
     */
    static String quarterLabel(LocalDate asOfOrUplDate) {
        if (asOfOrUplDate == null) {
            return "";
        }
        int q = (asOfOrUplDate.getMonthValue() - 1) / 3;
        return asOfOrUplDate.getYear() + ". " + ROMAN[q] + "-й квартал";
    }

    static String monthYearRu(LocalDate date) {
        if (date == null) {
            return "";
        }
        return MONTH_RU[date.getMonthValue() - 1] + " " + date.getYear();
    }

    private static SudzRsltPeriod findPeriod(SudzRsltDebt debt, LocalDate date) {
        for (SudzRsltPeriod period : debt.periods()) {
            if (date != null && date.equals(period.uplDate())) {
                return period;
            }
        }
        return null;
    }

    private static void writeHeaderCell(Row row, int col, String value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null && !value.isEmpty()) {
            cell.setCellValue(value);
        }
        cell.setCellStyle(style);
    }

    private static int writeTyped(Row row, int col, String value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value);
        }
        cell.setCellStyle(style);
        return col + 1;
    }

    private static int writeTyped(Row row, int col, Integer value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.doubleValue());
        }
        cell.setCellStyle(style);
        return col + 1;
    }

    private static int writeTyped(Row row, int col, Long value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.doubleValue());
        }
        cell.setCellStyle(style);
        return col + 1;
    }

    private static int writeTyped(Row row, int col, int value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value);
        cell.setCellStyle(style);
        return col + 1;
    }

    private static int writeTyped(Row row, int col, LocalDate value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.format(ISO));
        }
        cell.setCellStyle(style);
        return col + 1;
    }

    private static int writeMoney(Row row, int col, BigDecimal value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value.doubleValue());
        }
        cell.setCellStyle(style);
        return col + 1;
    }

    private enum ColKind {
        KEY, SIDE, TEXT, NUM, SUM, EMPTY
    }

    /**
     * Группа заливки заголовка (цвета эталона 26-0212).
     */
    private enum StyleBand {
        KEY, BASE, INV, OVERD, CURATOR, NEW, Q0, Q1, Q2, Q3, Q4;

        static StyleBand quarter(int sliceIndex) {
            return switch (sliceIndex % 5) {
                case 0 -> Q0;
                case 1 -> Q1;
                case 2 -> Q2;
                case 3 -> Q3;
                default -> Q4;
            };
        }

        String fillRgb() {
            return switch (this) {
                case KEY -> null;
                case BASE -> FILL_BASE;
                case INV -> FILL_INV;
                case OVERD -> FILL_OVERD;
                case CURATOR -> FILL_CURATOR;
                case NEW -> FILL_NEW;
                case Q0 -> QUARTER_FILLS[0];
                case Q1 -> QUARTER_FILLS[1];
                case Q2 -> QUARTER_FILLS[2];
                case Q3 -> QUARTER_FILLS[3];
                case Q4 -> QUARTER_FILLS[4];
            };
        }
    }

    private record ColumnDef(String human, String tech, ColKind kind, StyleBand band) {
    }

    private record SliceMeta(LocalDate uplDate, LocalDate labelDate) {
    }

    /**
     * Набор стилей XSSF по эталону 26-0212 (Calibri, границы, RGB-заливки).
     */
    private static final class Styles {
        private final XSSFWorkbook workbook;
        private final XSSFFont fontHuman;
        private final XSSFFont fontTech;
        private final XSSFFont fontSum;
        private final XSSFFont fontData;
        private final Map<String, XSSFCellStyle> humanCache = new LinkedHashMap<>();
        private final XSSFCellStyle techStyle;
        private final XSSFCellStyle sumTtl;
        private final XSSFCellStyle sumOverd;
        private final XSSFCellStyle sumPog;
        private final XSSFCellStyle sumEmpty;
        private final XSSFCellStyle data;
        private final XSSFCellStyle money;

        Styles(XSSFWorkbook workbook) {
            this.workbook = workbook;
            fontHuman = workbook.createFont();
            fontHuman.setFontName("Calibri");
            fontHuman.setFontHeightInPoints((short) 8);
            fontHuman.setBold(false);
            fontHuman.setColor(rgb("000000"));

            fontTech = workbook.createFont();
            fontTech.setFontName("Calibri");
            fontTech.setFontHeightInPoints((short) 9);
            fontTech.setBold(true);
            fontTech.setColor(rgb("000000"));

            fontSum = workbook.createFont();
            fontSum.setFontName("Calibri");
            fontSum.setFontHeightInPoints((short) 8);
            fontSum.setBold(true);
            fontSum.setColor(rgb(FONT_SUM_RGB));

            fontData = workbook.createFont();
            fontData.setFontName("Calibri");
            fontData.setFontHeightInPoints((short) 9);

            techStyle = baseHeader(fontTech, FILL_TECH, false);
            sumTtl = sumStyle(FILL_SUM_TTL);
            sumOverd = sumStyle(FILL_SUM_TTL);
            sumPog = sumStyle(FILL_SUM_POG);
            sumEmpty = workbook.createCellStyle();
            sumEmpty.setFont(fontHuman);

            data = workbook.createCellStyle();
            data.setFont(fontData);

            money = workbook.createCellStyle();
            money.setFont(fontData);
            money.setDataFormat(workbook.createDataFormat().getFormat(MONEY_FORMAT));
        }

        XSSFCellStyle human(StyleBand band) {
            String fill = band.fillRgb();
            String key = fill == null ? "none" : fill;
            return humanCache.computeIfAbsent(key, k -> baseHeader(fontHuman, fill, true));
        }

        XSSFCellStyle tech() {
            return techStyle;
        }

        XSSFCellStyle sumTtl() {
            return sumTtl;
        }

        XSSFCellStyle sumOverd() {
            return sumOverd;
        }

        XSSFCellStyle sumPogasheno() {
            return sumPog;
        }

        XSSFCellStyle sumEmpty() {
            return sumEmpty;
        }

        XSSFCellStyle data() {
            return data;
        }

        XSSFCellStyle money() {
            return money;
        }

        private XSSFCellStyle baseHeader(Font font, String fillRgb, boolean wrap) {
            XSSFCellStyle style = workbook.createCellStyle();
            style.setFont(font);
            style.setAlignment(HorizontalAlignment.CENTER);
            style.setVerticalAlignment(VerticalAlignment.CENTER);
            style.setWrapText(wrap);
            thinBorder(style);
            if (fillRgb != null) {
                style.setFillForegroundColor(rgb(fillRgb));
                style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            }
            return style;
        }

        private XSSFCellStyle sumStyle(String fillRgb) {
            XSSFCellStyle style = workbook.createCellStyle();
            style.setFont(fontSum);
            style.setAlignment(HorizontalAlignment.CENTER);
            style.setVerticalAlignment(VerticalAlignment.CENTER);
            style.setFillForegroundColor(rgb(fillRgb));
            style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            style.setDataFormat(workbook.createDataFormat().getFormat(MONEY_FORMAT));
            return style;
        }

        private static void thinBorder(XSSFCellStyle style) {
            style.setBorderTop(BorderStyle.THIN);
            style.setBorderBottom(BorderStyle.THIN);
            style.setBorderLeft(BorderStyle.THIN);
            style.setBorderRight(BorderStyle.THIN);
        }

        private static XSSFColor rgb(String hex6) {
            byte[] bytes = new byte[3];
            bytes[0] = (byte) Integer.parseInt(hex6.substring(0, 2), 16);
            bytes[1] = (byte) Integer.parseInt(hex6.substring(2, 4), 16);
            bytes[2] = (byte) Integer.parseInt(hex6.substring(4, 6), 16);
            return new XSSFColor(bytes, new DefaultIndexedColorMap());
        }
    }
}
