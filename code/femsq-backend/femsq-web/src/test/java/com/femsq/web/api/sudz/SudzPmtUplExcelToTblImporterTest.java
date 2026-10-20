package com.femsq.web.api.sudz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.femsq.database.model.sudz.SudzPmtUplTblRow;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Excel→Tbl платежей: якорь «№ докум.» + колонки по ключевым словам заголовков.
 */
class SudzPmtUplExcelToTblImporterTest {

    private SudzPmtUplExcelToTblImporter importer;

    @BeforeEach
    void setUp() {
        importer = new SudzPmtUplExcelToTblImporter(new AuditExcelCellReader());
    }

    @Test
    void parseCanonLayoutProducesTblRows() throws IOException {
        byte[] bytes = canonWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Sheet1", 2, log);

        assertEquals(1, rows.size());
        SudzPmtUplTblRow row = rows.get(0);
        assertEquals("BE01", row.ciputBE());
        assertEquals(606012, row.ciputAccount());
        assertEquals(1001, row.ciputCntrPrtNum());
        assertEquals("Кредитор Тест", row.ciputCntrPrtName());
        assertEquals("CAC-1", row.ciputCAC());
        assertEquals("Договор-1", row.ciputCnName());
        assertEquals("DOC-42", row.ciputCnInvDocCode());
        assertEquals(0, new BigDecimal("100.50").compareTo(row.ciputCnInvDocSum()));
        assertEquals(2, row.ciputUnloadKey());
        assertEquals(1, row.ciputSheetNum());
        assertNull(row.ciputSfKey());
        assertNull(row.ciputDueKey());
        assertNull(row.ciputDueGrp());

        String html = log.toHtml();
        assertTrue(html.contains("Sheet1"));
        assertTrue(html.contains("подготовлено"));
        assertTrue(html.contains("колонки по заголовкам"));
        assertFalse(html.contains("книга Excel открыта"));
        assertFalse(html.contains("добавлено"));
        assertFalse(html.contains("staging outline"));
    }

    @Test
    void parseNew767LayoutResolvesByHeaderKeywords() throws IOException {
        byte[] bytes = new767WorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_767501.xlsx", "Sheet1", 55, log);

        assertEquals(1, rows.size());
        SudzPmtUplTblRow row = rows.get(0);
        assertEquals("0001", row.ciputBE());
        assertEquals(767501, row.ciputAccount());
        assertEquals(28, row.ciputCntrPrtNum());
        assertEquals("Кредитор ВГ", row.ciputCntrPrtName());
        assertEquals("CST-9", row.ciputCAC());
        assertEquals("CN-77", row.ciputCnName());
        assertEquals(100, row.ciputAgentNum());
        assertEquals("Агент Имя", row.ciputAgentName());
        assertEquals("LINK-1", row.ciputLink());
        assertEquals("INV-9", row.ciputCnInv());
        assertEquals("PD-55", row.ciputCnInvDocCode());
        assertNull(row.ciputDueDate());
        assertNull(row.ciputCnInvDocSum());
        assertNull(row.ciputSfKey());
        assertTrue(log.toHtml().contains("колонки по заголовкам"));
        assertFalse(log.toHtml().contains("слишком близко к левому краю"));
    }

    @Test
    void traditionalOutlineAssignsDueGrpForRepeatedDue() throws IOException {
        byte[] bytes = traditionalOutlineWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();

        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_trad.xlsx", "Sheet1", 59, log);

        assertEquals(5, rows.size());
        assertTrue(log.toHtml().contains("staging outline"));
        assertTrue(log.toHtml().contains("жёлтых ключей <b>4</b>"));

        // один СФ файла + один отрезок стройки
        assertEquals(1, rows.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count());
        assertEquals(1, rows.stream().map(SudzPmtUplTblRow::ciputCacSpanKey).distinct().count());

        Set<Integer> dueKeys = rows.stream()
                .map(SudzPmtUplTblRow::ciputDueKey)
                .collect(Collectors.toSet());
        assertEquals(4, dueKeys.size());

        List<SudzPmtUplTblRow> due2802 = rows.stream()
                .filter(r -> r.ciputDueDate() != null
                        && r.ciputDueDate().toLocalDate().equals(LocalDate.of(2026, 2, 28)))
                .toList();
        assertEquals(3, due2802.size()); // D1 + D4 + D5
        Set<Integer> grps = due2802.stream()
                .map(SudzPmtUplTblRow::ciputDueGrp)
                .collect(Collectors.toSet());
        assertEquals(Set.of(1, 2), grps);
        assertEquals(2, due2802.stream().map(SudzPmtUplTblRow::ciputDueKey).distinct().count());
    }

    @Test
    void traditionalOutlineSuspiciousBnThreeYellowKeys() throws IOException {
        byte[] bytes = traditionalBnWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_bn.xlsx", "Sheet1", 59, log);

        assertEquals(3, rows.size());
        assertEquals(1, rows.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count());
        assertEquals(3, rows.stream().map(SudzPmtUplTblRow::ciputDueKey).distinct().count());
        assertTrue(rows.stream().allMatch(r -> Objects.equals(r.ciputDueGrp(), 1)));
    }

    /**
     * QII 1.13.7: два разных СФ под одним L6 — разные sfKey; один СФ в двух L6 —
     * тот же sfKey и разные cacSpan; dueKey/dueGrp пусты.
     */
    @Test
    void qiiOutlineSfFromDocNotL6Boundary() throws IOException {
        byte[] bytes = qiiOutlineWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_qii.xlsx", "Sheet1", 55, log);

        assertEquals(3, rows.size());
        assertTrue(log.toHtml().contains("staging QII"));
        assertTrue(rows.stream().allMatch(r -> r.ciputDueKey() == null && r.ciputDueGrp() == null));
        assertTrue(rows.stream().allMatch(r -> r.ciputDueDate() == null));

        SudzPmtUplTblRow a1 = rows.get(0);
        SudzPmtUplTblRow b1 = rows.get(1);
        SudzPmtUplTblRow a2 = rows.get(2);

        assertEquals("INV-A", a1.ciputCnInv());
        assertEquals("INV-B", b1.ciputCnInv());
        assertEquals("INV-A", a2.ciputCnInv());
        assertNotNull(a1.ciputSfKey());
        assertNotEquals(a1.ciputSfKey(), b1.ciputSfKey());
        assertEquals(a1.ciputSfKey(), a2.ciputSfKey());
        assertEquals(a1.ciputCacSpanKey(), b1.ciputCacSpanKey());
        assertNotEquals(a1.ciputCacSpanKey(), a2.ciputCacSpanKey());
        assertEquals(2, rows.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count());
        assertEquals(2, rows.stream().map(SudzPmtUplTblRow::ciputCacSpanKey).distinct().count());
    }

    @Test
    void smokeExportQii767501StagingKeys() throws IOException {
        Path path = Path.of("/mnt/nb-win-share/femsq/excel/2026-06/debit/export_767501_26-0817.XLSX");
        assumeTrue(Files.isRegularFile(path), "QII export_767501_26-0817 недоступен");

        byte[] bytes = Files.readAllBytes(path);
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, path.getFileName().toString(), "Sheet1", 55, log);

        assertEquals(9806, rows.size());
        assertTrue(log.toHtml().contains("staging QII"));
        assertTrue(rows.stream().allMatch(r -> r.ciputDueKey() == null && r.ciputDueGrp() == null));
        assertTrue(rows.stream().allMatch(r -> r.ciputSfKey() != null));
        long sfKeys = rows.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count();
        assertEquals(2698, sfKeys);
        // L6 не граница СФ: номер разнесён по двум отрезкам стройки — один sfKey
        List<SudzPmtUplTblRow> multiSpan = rows.stream()
                .filter(r -> "2011/002019".equals(r.ciputCnInv()))
                .toList();
        assumeTrue(multiSpan.size() >= 2, "эталонный номер СФ в файле");
        assertEquals(1, multiSpan.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count());
        assertTrue(multiSpan.stream().map(SudzPmtUplTblRow::ciputCacSpanKey).distinct().count() > 1);
    }

    @Test
    void smokeExport59StagingKeys() throws IOException {
        Path path = Path.of(
                "/mnt/d/wire-guard-share-nb-win/femsq/excel/2025-12/debit/export_26-0130_767501.XLSX");
        assumeTrue(Files.isRegularFile(path), "эталонный export_26-0130_767501 недоступен");

        byte[] bytes = Files.readAllBytes(path);
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, path.getFileName().toString(), "Sheet1", 59, log);

        assertEquals(15942, rows.size());
        long dueKeys = rows.stream().map(SudzPmtUplTblRow::ciputDueKey).filter(Objects::nonNull).distinct().count();
        assertEquals(7575, dueKeys);

        List<SudzPmtUplTblRow> case0620 = rows.stream()
                .filter(r -> "0620CR000478".equals(r.ciputCnInv()))
                .filter(r -> "051-2004018".equals(r.ciputCAC()))
                .filter(r -> r.ciputDueDate() != null
                        && r.ciputDueDate().toLocalDate().equals(LocalDate.of(2026, 2, 28)))
                .toList();
        assertFalse(case0620.isEmpty());
        Set<Integer> grps = case0620.stream()
                .map(SudzPmtUplTblRow::ciputDueGrp)
                .collect(Collectors.toSet());
        assertEquals(Set.of(1, 2), grps);
        assertEquals(2, case0620.stream().map(SudzPmtUplTblRow::ciputDueKey).distinct().count());

        List<SudzPmtUplTblRow> bnKs14 = rows.stream()
                .filter(r -> "КС-14".equals(r.ciputCnName()))
                .filter(r -> "б/н".equals(r.ciputCnInv()))
                .toList();
        assertEquals(3, bnKs14.size());
        assertEquals(1, bnKs14.stream().map(SudzPmtUplTblRow::ciputSfKey).distinct().count());
        assertEquals(3, bnKs14.stream().map(SudzPmtUplTblRow::ciputDueKey).distinct().count());
        assertNotNull(bnKs14.get(0).ciputDueKey());
    }

    @Test
    void missingSheetYieldsEmpty() throws IOException {
        byte[] bytes = canonWorkbookBytes();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Other", 2, log);
        assertEquals(0, rows.size());
        assertTrue(log.toHtml().contains("не найден"));
        assertTrue(log.toHtml().contains("итог"));
    }

    @Test
    void subtotalRowWithoutDocCodeIsSkipped() throws IOException {
        byte[] bytes = workbookWithWeakRow();
        SudzDbtUplProgressLog log = new SudzDbtUplProgressLog();
        List<SudzPmtUplTblRow> rows = importer.parse(bytes, "export_test.xlsx", "Sheet1", 2, log);
        assertEquals(1, rows.size());
        assertEquals("DOC-1", rows.get(0).ciputCnInvDocCode());
        String html = log.toHtml();
        assertTrue(html.contains("только строки с «№ докум.»"));
        assertFalse(html.contains("без «№ докум.»"));
    }

    @Test
    void normalizeHeaderStripsPunctuation() {
        assertEquals("№докум", SudzPmtUplExcelToTblImporter.normalizeHeader("№ докум."));
        assertEquals("сальдоконечноедт", SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо конечное Дт"));
        assertEquals("дпроводки", SudzPmtUplExcelToTblImporter.normalizeHeader("Д/проводки"));
    }

    @Test
    void abbreviatedClosingBalanceHeadersMapToOverdueColumns() {
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.DBT_OVERD,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо кон.Дт просроченное")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.DBT_OVERD_NOT,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо кон.Дт непросроченн.")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.CDT_OVERD,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо кон.Кт просроченное")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.CDT_OVERD_NOT,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо кон.Кт непросроченн.")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.DBT,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо конечное Дт")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.CDT,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо конечное по Кт")));
        assertEquals(
                SudzPmtUplExcelToTblImporter.Col.BLNS,
                SudzPmtUplExcelToTblImporter.matchSingle(
                        SudzPmtUplExcelToTblImporter.normalizeHeader("Сальдо конечное")));
    }

    private static byte[] canonWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeCanonHeader(sheet.createRow(0));
            Row data = sheet.createRow(1);
            data.createCell(0).setCellValue("BE01");
            data.createCell(1).setCellValue(606012);
            data.createCell(2).setCellValue(1001);
            data.createCell(3).setCellValue("Кредитор Тест");
            data.createCell(4).setCellValue("CAC-1");
            data.createCell(7).setCellValue("Договор-1");
            data.createCell(20).setCellValue("DOC-42");
            data.createCell(23).setCellValue(100.50);
            return toBytes(wb);
        }
    }

    /** Layout как export_767501_26-0817.raw (якорь «№ докум.» @ col 18). */
    private static byte[] new767WorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            String[] titles = {
                    "БЕ", "Опер.сегмент", "Код стройки", "Счет ГК", "Вид контрагента",
                    "Кредитор", "Наименование кредитора", "Договор", "Агент", "Агент",
                    "Сальдо начальное Дт", "Сальдо начальное по Кт", "Сальдо начальное",
                    "Дебетовый оборот", "Кредитовый оборот",
                    "Сальдо конечное Дт", "Сальдо конечное по Кт", "Сальдо конечное",
                    SudzPmtUplExcelToTblImporter.ANCHOR_DOC_NUM,
                    "Д/проводки", "Д/документ", "Д/выравн.", "Ссылка", "Присвоение",
                    "Д/К", "КС", "Нулевые показатели", "Частичное выравнивание",
                    "ПричСторн", "ДокСторно"
            };
            Row header = sheet.createRow(0);
            for (int c = 0; c < titles.length; c++) {
                header.createCell(c).setCellValue(titles[c]);
            }
            Row data = sheet.createRow(1);
            data.createCell(0).setCellValue("0001");
            data.createCell(2).setCellValue("CST-9");
            data.createCell(3).setCellValue(767501);
            data.createCell(5).setCellValue(28);
            data.createCell(6).setCellValue("Кредитор ВГ");
            data.createCell(7).setCellValue("CN-77");
            data.createCell(8).setCellValue(100);
            data.createCell(9).setCellValue("Агент Имя");
            data.createCell(15).setCellValue(10.0);
            data.createCell(16).setCellValue(0.0);
            data.createCell(17).setCellValue(10.0);
            data.createCell(18).setCellValue("PD-55");
            data.createCell(22).setCellValue("LINK-1");
            data.createCell(23).setCellValue("INV-9");
            return toBytes(wb);
        }
    }

    private static byte[] workbookWithWeakRow() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            writeCanonHeader(sheet.createRow(0));
            Row ok = sheet.createRow(1);
            ok.createCell(0).setCellValue("BE01");
            ok.createCell(1).setCellValue(606012);
            ok.createCell(20).setCellValue("DOC-1");
            Row weak = sheet.createRow(2);
            weak.createCell(1).setCellValue(606012);
            weak.createCell(3).setCellValue("Без номера документа");
            return toBytes(wb);
        }
    }

    /**
     * Мини-дерево как у {@code 0620CR000478}: два жёлтых итога с одним сроком 28.02
     * и два других срока между ними.
     */
    private static byte[] traditionalOutlineWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            CellStyle dateStyle = dateStyle(wb);
            writeCanonHeader(sheet.createRow(0));
            int r = 1;
            r = addWhite(sheet, dateStyle, r, 51, "КС-51", "0620CR000478", "051-2004018",
                    LocalDate.of(2026, 2, 28), "D1", 10);
            r = addYellow(sheet, dateStyle, r, LocalDate.of(2026, 2, 28), 10);
            r = addWhite(sheet, dateStyle, r, 51, "КС-51", "0620CR000478", "051-2004018",
                    LocalDate.of(2025, 12, 31), "D2", 20);
            r = addYellow(sheet, dateStyle, r, LocalDate.of(2025, 12, 31), 20);
            r = addWhite(sheet, dateStyle, r, 51, "КС-51", "0620CR000478", "051-2004018",
                    LocalDate.of(2026, 1, 28), "D3", 30);
            r = addYellow(sheet, dateStyle, r, LocalDate.of(2026, 1, 28), 30);
            r = addWhite(sheet, dateStyle, r, 51, "КС-51", "0620CR000478", "051-2004018",
                    LocalDate.of(2026, 2, 28), "D4", 15);
            r = addWhite(sheet, dateStyle, r, 51, "КС-51", "0620CR000478", "051-2004018",
                    LocalDate.of(2026, 2, 28), "D5", 25);
            addYellow(sheet, dateStyle, r, LocalDate.of(2026, 2, 28), 40);
            return toBytes(wb);
        }
    }

    /**
     * Мини-дерево QII: два СФ под одним L6, затем тот же INV-A под другим L6.
     * Колонки как export_767501_26-0817.
     */
    private static byte[] qiiOutlineWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            String[] titles = {
                    "БЕ", "Опер.сегмент", "Код стройки", "Счет ГК", "Вид контрагента",
                    "Кредитор", "Наименование кредитора", "Договор", "Агент", "Агент",
                    "Сальдо начальное Дт", "Сальдо начальное по Кт", "Сальдо начальное",
                    "Дебетовый оборот", "Кредитовый оборот",
                    "Сальдо конечное Дт", "Сальдо конечное по Кт", "Сальдо конечное",
                    SudzPmtUplExcelToTblImporter.ANCHOR_DOC_NUM,
                    "Д/проводки", "Д/документ", "Д/выравн.", "Ссылка", "Присвоение",
                    "Д/К", "КС", "Нулевые показатели", "Частичное выравнивание",
                    "ПричСторн", "ДокСторно"
            };
            Row header = sheet.createRow(0);
            for (int c = 0; c < titles.length; c++) {
                header.createCell(c).setCellValue(titles[c]);
            }
            int r = 1;
            r = addQiiWhite(sheet, r, 1001, "КС-51", "INV-A", "CAC-1", "D1");
            r = addQiiWhite(sheet, r, 1001, "КС-51", "INV-B", "CAC-1", "D2");
            r = addQiiYellow(sheet, r, 6, "CAC-1");
            // тот же INV-A в другом отрезке стройки (L6 не граница СФ)
            r = addQiiWhite(sheet, r, 1001, "КС-51", "INV-A", "CAC-2", "D3");
            addQiiYellow(sheet, r, 6, "CAC-2");
            return toBytes(wb);
        }
    }

    private static int addQiiWhite(
            Sheet sheet, int rowIdx, int ctpt, String cn, String inv, String cac, String doc
    ) {
        XSSFRow row = (XSSFRow) sheet.createRow(rowIdx);
        row.getCTRow().setOutlineLevel((short) 7);
        row.createCell(0).setCellValue("0001");
        row.createCell(2).setCellValue(cac);
        row.createCell(3).setCellValue(767501);
        row.createCell(5).setCellValue(ctpt);
        row.createCell(6).setCellValue("Кредитор");
        row.createCell(7).setCellValue(cn);
        row.createCell(18).setCellValue(doc);
        row.createCell(23).setCellValue(inv);
        return rowIdx + 1;
    }

    private static int addQiiYellow(Sheet sheet, int rowIdx, int level, String cac) {
        XSSFRow row = (XSSFRow) sheet.createRow(rowIdx);
        row.getCTRow().setOutlineLevel((short) level);
        row.createCell(2).setCellValue(cac);
        row.createCell(3).setCellValue(767501);
        return rowIdx + 1;
    }

    /** Три белых «б/н» КС-14 под тремя жёлтыми — три dueKey, один sfKey. */
    private static byte[] traditionalBnWorkbookBytes() throws IOException {
        try (XSSFWorkbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            CellStyle dateStyle = dateStyle(wb);
            writeCanonHeader(sheet.createRow(0));
            int r = 1;
            r = addWhite(sheet, dateStyle, r, 14, "КС-14", "б/н", "051-1",
                    LocalDate.of(2026, 1, 15), "5900202347", 0);
            r = addYellow(sheet, dateStyle, r, LocalDate.of(2026, 1, 15), 0);
            r = addWhite(sheet, dateStyle, r, 14, "КС-14", "б/н", "051-1",
                    LocalDate.of(2026, 1, 20), "5400199014", 0);
            r = addYellow(sheet, dateStyle, r, LocalDate.of(2026, 1, 20), 0);
            r = addWhite(sheet, dateStyle, r, 14, "КС-14", "б/н", "051-1",
                    LocalDate.of(2026, 2, 1), "5400224218", -10);
            addYellow(sheet, dateStyle, r, LocalDate.of(2026, 2, 1), -10);
            return toBytes(wb);
        }
    }

    private static CellStyle dateStyle(XSSFWorkbook wb) {
        CreationHelper helper = wb.getCreationHelper();
        CellStyle style = wb.createCellStyle();
        style.setDataFormat(helper.createDataFormat().getFormat("dd.mm.yyyy"));
        return style;
    }

    private static int addWhite(
            Sheet sheet,
            CellStyle dateStyle,
            int rowIdx,
            int ctpt,
            String cn,
            String inv,
            String cac,
            LocalDate due,
            String doc,
            double blns
    ) {
        XSSFRow row = (XSSFRow) sheet.createRow(rowIdx);
        row.getCTRow().setOutlineLevel((short) 4);
        row.createCell(0).setCellValue("BE01");
        row.createCell(1).setCellValue(767501);
        row.createCell(2).setCellValue(ctpt);
        row.createCell(3).setCellValue("Кредитор");
        row.createCell(4).setCellValue(cac);
        row.createCell(7).setCellValue(cn);
        row.createCell(9).setCellValue(inv);
        var dueCell = row.createCell(12);
        dueCell.setCellValue(toDate(due));
        dueCell.setCellStyle(dateStyle);
        row.createCell(19).setCellValue(blns);
        row.createCell(20).setCellValue(doc);
        return rowIdx + 1;
    }

    private static int addYellow(
            Sheet sheet, CellStyle dateStyle, int rowIdx, LocalDate due, double blns
    ) {
        XSSFRow row = (XSSFRow) sheet.createRow(rowIdx);
        row.getCTRow().setOutlineLevel((short) 3);
        var dueCell = row.createCell(12);
        dueCell.setCellValue(toDate(due));
        dueCell.setCellStyle(dateStyle);
        row.createCell(19).setCellValue(blns);
        return rowIdx + 1;
    }

    private static Date toDate(LocalDate due) {
        return Date.from(due.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }

    private static void writeCanonHeader(Row header) {
        String[] titles = {
                "БЕ", "Счет ГК", "Кредитор", "Наименование кредитора", "Код стройки",
                "Агент", "Агент", "Договор", "Ссылка", "Присвоение",
                "Д/проводки", "Д/документ", "Срок оплаты",
                "Сальдо конечное Дт", "Сальдо кон.Дт просроченное", "Сальдо кон.Дт непросроченн.",
                "Сальдо конечное по Кт", "Сальдо кон.Кт просроченное", "Сальдо кон.Кт непросроченн.",
                "Сальдо конечное",
                SudzPmtUplExcelToTblImporter.ANCHOR_DOC_NUM,
                "Д/выравн.", "БазДата", "Сумма документа", "ПричСторн", "ДокСторно"
        };
        for (int c = 0; c < titles.length; c++) {
            header.createCell(c).setCellValue(titles[c]);
        }
    }

    private static byte[] toBytes(XSSFWorkbook wb) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wb.write(out);
        return out.toByteArray();
    }
}
