package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzDbtUplFileSh;
import com.femsq.database.model.sudz.SudzDbtUplTblRow;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Excel → {@code CnInvDbtUplTbl}: порт VBA {@code AccountSheetTest} / {@code ReceivablesTest}.
 * Лог — хронология сверху вниз, свёртка по листу.
 */
@Component
public class SudzDbtUplExcelToTblImporter {

    private static final String H_INV = "Документ основания (счет-фактура)";
    private static final String H_ORG_NUM = "№ контрагента";
    private static final String H_ORG_NAME = "Контрагент";
    private static final String H_ITN = "ИНН";
    private static final String H_CN = "Договор";
    private static final String H_CN_DATE = "Дата договора";
    private static final String H_FORM = "Дата образования";
    private static final String H_MAT = "Срок погашения";
    private static final String H_DEBT = "Всего сумма задолженности в рублях";
    private static final String H_OVERDUE = "Просроченная задолженность в рублях";
    private static final String H_DOC = "Документ основания (присвоение ГК)";
    private static final String H_LINK = "Ссылка";

    private final AuditExcelCellReader cellReader;

    /**
     * @param cellReader чтение ячеек
     */
    public SudzDbtUplExcelToTblImporter(AuditExcelCellReader cellReader) {
        this.cellReader = Objects.requireNonNull(cellReader, "cellReader");
    }

    /**
     * Разбор книги по списку FileSh. Пишет в {@code log} хронологически (начало сверху).
     *
     * @param excelBytes содержимое xlsx
     * @param fileName имя файла (для лога)
     * @param sheets листы FileSh
     * @param unloadKey upl_key
     * @param log лог шага excelToTbl (уже внутри open шага)
     * @return строки Tbl
     * @throws IOException ошибка POI
     */
    public List<SudzDbtUplTblRow> parse(
            byte[] excelBytes,
            String fileName,
            List<SudzDbtUplFileSh> sheets,
            int unloadKey,
            SudzDbtUplProgressLog log
    ) throws IOException {
        Objects.requireNonNull(excelBytes, "excelBytes");
        Objects.requireNonNull(sheets, "sheets");
        Objects.requireNonNull(log, "log");
        List<SudzDbtUplTblRow> rows = new ArrayList<>();
        int[] findDbtNum = {0};

        log.line(SudzDbtUplProgressLog.now() + " — файл *<font color=\"green\">"
                + SudzDbtUplProgressLog.escape(fileName) + "</font>* принят для чтения ("
                + excelBytes.length + " байт)");

        try (InputStream in = new ByteArrayInputStream(excelBytes);
             Workbook workbook = WorkbookFactory.create(in)) {
            log.line(SudzDbtUplProgressLog.now()
                    + " — *<b><font color=\"green\">книга Excel открыта</font></b>*");

            Map<String, Sheet> byName = new HashMap<>();
            for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
                Sheet sheet = workbook.getSheetAt(i);
                byName.put(sheet.getSheetName(), sheet);
            }

            for (SudzDbtUplFileSh sh : sheets) {
                if (!sh.cidufsTest()) {
                    log.open("Лист <font color=\"Orchid\"><b>"
                                    + SudzDbtUplProgressLog.escape(sh.cidufsSheet())
                                    + "</b></font> — не рассматривается",
                            false);
                    log.line("<font color=\"Goldenrod\">пропущен</font> по флагу cidufsTest");
                    log.close();
                    continue;
                }
                Sheet sheet = byName.get(sh.cidufsSheet());
                if (sheet == null) {
                    log.open("Лист <font color=\"Salmon\"><b>"
                                    + SudzDbtUplProgressLog.escape(sh.cidufsSheet())
                                    + "</b></font> — не обнаружен",
                            false);
                    log.line("Листа нет в книге");
                    log.close();
                    continue;
                }
                parseSheet(sheet, sh, unloadKey, rows, findDbtNum, log);
            }

            log.line(SudzDbtUplProgressLog.now()
                    + " — *<b><font color=\"blue\">книга Excel закрыта</font></b>*");
        }

        log.line("<font color=\"DarkGreen\"><b>итог</b></font>: в буфер Tbl подготовлено строк: "
                + rows.size() + " (FindDbtNum max=" + findDbtNum[0] + ")");
        return List.copyOf(rows);
    }

    private void parseSheet(
            Sheet sheet,
            SudzDbtUplFileSh sh,
            int unloadKey,
            List<SudzDbtUplTblRow> rows,
            int[] findDbtNum,
            SudzDbtUplProgressLog parent
    ) {
        SudzDbtUplProgressLog sheetLog = new SudzDbtUplProgressLog();
        Map<String, int[]> headers = findHeaders(sheet);
        logHeader(sheetLog, H_INV, headers.get(H_INV));
        logHeader(sheetLog, H_ORG_NUM, headers.get(H_ORG_NUM));
        logHeader(sheetLog, H_ORG_NAME, headers.get(H_ORG_NAME));
        logHeader(sheetLog, H_ITN, headers.get(H_ITN));
        logHeader(sheetLog, H_CN, headers.get(H_CN));
        logHeader(sheetLog, H_CN_DATE, headers.get(H_CN_DATE));
        logHeader(sheetLog, H_FORM, headers.get(H_FORM));
        logHeader(sheetLog, H_MAT, headers.get(H_MAT));
        logHeader(sheetLog, H_DEBT, headers.get(H_DEBT));
        logHeader(sheetLog, H_OVERDUE, headers.get(H_OVERDUE));
        logHeader(sheetLog, H_DOC, headers.get(H_DOC));
        logHeader(sheetLog, H_LINK, headers.get(H_LINK));

        int[] inv = headers.get(H_INV);
        int[] orgNum = headers.get(H_ORG_NUM);
        int[] orgName = headers.get(H_ORG_NAME);
        int[] cn = headers.get(H_CN);
        int[] cnDate = headers.get(H_CN_DATE);
        int[] form = headers.get(H_FORM);
        int[] mat = headers.get(H_MAT);
        int[] debt = headers.get(H_DEBT);
        int[] overdue = headers.get(H_OVERDUE);
        int added = 0;
        if (inv == null || orgNum == null || orgName == null || cn == null || cnDate == null
                || form == null || mat == null || debt == null || overdue == null) {
            sheetLog.line("<font color=\"red\">не найдены все ячейки, необходимые для задолженности</font>");
        } else {
            sheetLog.line("найдены ячейки, необходимые для внесения задолженности");
            int invCol = inv[1];
            int headerRow = inv[0];
            int lastRow = sheet.getLastRowNum();
            int sheetRowNo = 0;
            for (int r = headerRow + 1; r <= lastRow; r++) {
                Row row = sheet.getRow(r);
                if (row == null) {
                    continue;
                }
                Cell invCell = row.getCell(invCol);
                if (!rowLooksLikeDebt(row, invCol)) {
                    continue;
                }
                sheetRowNo++;
                findDbtNum[0]++;
                String invVal = cellReader.readString(invCell);
                rows.add(new SudzDbtUplTblRow(
                        findDbtNum[0],
                        sh.cidufsAccount(),
                        softInt(row.getCell(orgNum[1])),
                        cellReader.readString(row.getCell(orgName[1])),
                        headerValue(headers, H_ITN, row),
                        cellReader.readString(row.getCell(cn[1])),
                        toDateTime(cellReader.readDate(row.getCell(cnDate[1]))),
                        invVal,
                        toDateTime(cellReader.readDate(row.getCell(form[1]))),
                        toDateTime(cellReader.readDate(row.getCell(mat[1]))),
                        softDecimal(row.getCell(debt[1])),
                        softDecimal(row.getCell(overdue[1])),
                        headerValue(headers, H_DOC, row),
                        headerValue(headers, H_LINK, row),
                        sh.cidufsKey(),
                        sheetRowNo,
                        unloadKey
                ));
                added++;
                sheetLog.line("счет-фактура <font color=\"Teal\">"
                        + SudzDbtUplProgressLog.escape(invVal == null ? "" : invVal)
                        + "</font> обнаружен. <font color=\"DarkGreen\">Добавлено</font>.");
            }
        }

        parent.open("Лист <font color=\"Teal\"><b>"
                        + SudzDbtUplProgressLog.escape(sh.cidufsSheet())
                        + "</b></font> — " + added + " строк",
                false);
        parent.raw(sheetLog.toHtml());
        parent.close();
    }

    private String headerValue(Map<String, int[]> headers, String name, Row row) {
        int[] pos = headers.get(name);
        if (pos == null) {
            return null;
        }
        return cellReader.readString(row.getCell(pos[1]));
    }

    private Integer softInt(Cell cell) {
        var result = cellReader.readIntResult(cell);
        return result.ok() ? result.value() : null;
    }

    private BigDecimal softDecimal(Cell cell) {
        var result = cellReader.readDecimalResult(cell);
        return result.ok() ? result.value() : null;
    }

    /**
     * VBA: непустая СФ или offset -1/-2/-5.
     */
    private boolean rowLooksLikeDebt(Row row, int invCol) {
        if (notBlank(cellReader.readString(row.getCell(invCol)))) {
            return true;
        }
        if (invCol >= 1 && notBlank(cellReader.readString(row.getCell(invCol - 1)))) {
            return true;
        }
        if (invCol >= 2 && notBlank(cellReader.readString(row.getCell(invCol - 2)))) {
            return true;
        }
        return invCol >= 5 && notBlank(cellReader.readString(row.getCell(invCol - 5)));
    }

    private Map<String, int[]> findHeaders(Sheet sheet) {
        Map<String, int[]> found = new HashMap<>();
        String[] names = {
                H_INV, H_ORG_NUM, H_ORG_NAME, H_ITN, H_CN, H_CN_DATE, H_FORM, H_MAT, H_DEBT, H_OVERDUE, H_DOC, H_LINK
        };
        int lastRow = Math.min(sheet.getLastRowNum(), 80);
        for (int r = 0; r <= lastRow; r++) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            short lastCell = row.getLastCellNum();
            if (lastCell < 0) {
                continue;
            }
            for (int c = 0; c < lastCell; c++) {
                String text = cellReader.readString(row.getCell(c));
                if (text == null) {
                    continue;
                }
                String trimmed = text.trim();
                for (String name : names) {
                    if (!found.containsKey(name) && name.equals(trimmed)) {
                        found.put(name, new int[]{r, c});
                    }
                }
            }
        }
        return found;
    }

    private void logHeader(SudzDbtUplProgressLog log, String title, int[] pos) {
        if (pos != null) {
            log.line("найдена ячейка <b>*" + SudzDbtUplProgressLog.escape(title) + "*</b> — колонка "
                    + (pos[1] + 1) + ", строка " + (pos[0] + 1));
        } else {
            log.line("ячейка <b>*" + SudzDbtUplProgressLog.escape(title)
                    + "*</b> <font color=\"red\">не найдена</font>");
        }
    }

    private static LocalDateTime toDateTime(LocalDate date) {
        return date == null ? null : LocalDateTime.of(date, LocalTime.MIDNIGHT);
    }

    private static boolean notBlank(String value) {
        return value != null && !value.isBlank();
    }
}
