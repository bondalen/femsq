package com.femsq.web.api.sudz;

import com.femsq.database.model.sudz.SudzPmtUplTblRow;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Excel → {@code CnInvPmtUplTbl}: якорь VBA {@code Find("№ докум.")}, Offset A–Z
 * ({@code export_offset-map.md}).
 * <p>
 * Лог — сжатый (0074): блокеры и сводка листа; без построчного «добавлено».
 * </p>
 */
@Component
public class SudzPmtUplExcelToTblImporter {

    /** Точный заголовок якоря (xlWhole). */
    static final String ANCHOR_DOC_NUM = "№ докум.";

    /** Offset 0 = колонка U относительно якоря; A = −20 … Z = +5. */
    private static final int OFF_BE = -20;
    private static final int OFF_ACCOUNT = -19;
    private static final int OFF_CTPT_NUM = -18;
    private static final int OFF_CTPT_NAME = -17;
    private static final int OFF_CAC = -16;
    private static final int OFF_AGENT_NUM = -15;
    private static final int OFF_AGENT_NAME = -14;
    private static final int OFF_CN_NAME = -13;
    private static final int OFF_LINK = -12;
    private static final int OFF_CN_INV = -11;
    private static final int OFF_ENTRY = -10;
    private static final int OFF_DOC_DATE = -9;
    private static final int OFF_DUE = -8;
    private static final int OFF_DBT = -7;
    private static final int OFF_DBT_OVERD = -6;
    private static final int OFF_DBT_OVERD_NOT = -5;
    private static final int OFF_CDT = -4;
    private static final int OFF_CDT_OVERD = -3;
    private static final int OFF_CDT_OVERD_NOT = -2;
    private static final int OFF_BLNS = -1;
    private static final int OFF_DOC_CODE = 0;
    private static final int OFF_ALIGN = 1;
    private static final int OFF_BASE = 2;
    private static final int OFF_DOC_SUM = 3;
    private static final int OFF_STORNO_REASON = 4;
    private static final int OFF_STORNO_DOC = 5;

    private final AuditExcelCellReader cellReader;

    /**
     * @param cellReader чтение ячеек
     */
    public SudzPmtUplExcelToTblImporter(AuditExcelCellReader cellReader) {
        this.cellReader = Objects.requireNonNull(cellReader, "cellReader");
    }

    /**
     * Разбор книги по имени листа {@code cipufSheet}.
     *
     * @param excelBytes содержимое xlsx
     * @param fileName имя файла (для сообщений об ошибке)
     * @param sheetName имя листа из File
     * @param unloadKey {@code cn_inv_pm_key}
     * @param log сжатый лог (блокеры + сводка)
     * @return строки staging
     * @throws IOException ошибка POI
     */
    public List<SudzPmtUplTblRow> parse(
            byte[] excelBytes,
            String fileName,
            String sheetName,
            int unloadKey,
            SudzDbtUplProgressLog log
    ) throws IOException {
        Objects.requireNonNull(excelBytes, "excelBytes");
        Objects.requireNonNull(log, "log");
        List<SudzPmtUplTblRow> rows = new ArrayList<>();

        try (InputStream in = new ByteArrayInputStream(excelBytes);
             Workbook workbook = WorkbookFactory.create(in)) {
            Optional<Sheet> sheetOpt = resolveSheet(workbook, sheetName, log);
            if (sheetOpt.isEmpty()) {
                log.line("<font color=\"DarkOrange\"><b>итог</b></font>: в буфер Tbl 0 строк"
                        + " (файл «" + SudzDbtUplProgressLog.escape(fileName) + "»).");
                return List.of();
            }
            Sheet sheet = sheetOpt.get();
            int sheetNum = workbook.getSheetIndex(sheet) + 1;
            parseSheet(sheet, sheetNum, unloadKey, rows, log);
        }
        return List.copyOf(rows);
    }

    private Optional<Sheet> resolveSheet(
            Workbook workbook,
            String sheetName,
            SudzDbtUplProgressLog log
    ) {
        String wanted = sheetName == null ? "" : sheetName.trim();
        if (wanted.isEmpty()) {
            log.line("<font color=\"red\">в File не задан лист</font> (cipufSheet пуст)."
                    + " Укажите имя листа как в Excel.");
            return Optional.empty();
        }
        for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
            Sheet sheet = workbook.getSheetAt(i);
            if (wanted.equalsIgnoreCase(sheet.getSheetName())) {
                return Optional.of(sheet);
            }
        }
        log.line("<font color=\"red\">лист «"
                + SudzDbtUplProgressLog.escape(wanted)
                + "» не найден в книге</font>. Исправьте cipufSheet.");
        return Optional.empty();
    }

    private void parseSheet(
            Sheet sheet,
            int sheetNum,
            int unloadKey,
            List<SudzPmtUplTblRow> rows,
            SudzDbtUplProgressLog log
    ) {
        Optional<int[]> anchor = findAnchor(sheet);
        if (anchor.isEmpty()) {
            log.line("<font color=\"red\">якорь «"
                    + SudzDbtUplProgressLog.escape(ANCHOR_DOC_NUM)
                    + "» не найден</font> на листе «"
                    + SudzDbtUplProgressLog.escape(sheet.getSheetName())
                    + "» (поиск xlWhole в первых строках).");
            return;
        }
        int headerRow = anchor.get()[0];
        int anchorCol = anchor.get()[1];
        if (anchorCol + OFF_BE < 0) {
            log.line("<font color=\"red\">якорь «"
                    + SudzDbtUplProgressLog.escape(ANCHOR_DOC_NUM)
                    + "» слишком близко к левому краю</font> (нужна колонка U / индекс ≥ 20)"
                    + " на листе «"
                    + SudzDbtUplProgressLog.escape(sheet.getSheetName()) + "».");
            return;
        }

        int lastRow = sheet.getLastRowNum();
        int added = 0;
        int weakWithoutDoc = 0;
        for (int r = headerRow + 1; r <= lastRow; r++) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            if (!rowLooksLikePayment(row, anchorCol)) {
                continue;
            }
            String doc = cellReader.readString(row.getCell(anchorCol + OFF_DOC_CODE));
            if (!notBlank(doc)) {
                weakWithoutDoc++;
            }
            rows.add(mapRow(row, anchorCol, sheetNum, unloadKey));
            added++;
        }

        StringBuilder summary = new StringBuilder();
        summary.append("лист <font color=\"Teal\"><b>")
                .append(SudzDbtUplProgressLog.escape(sheet.getSheetName()))
                .append("</b></font>: подготовлено <b>").append(added).append("</b> строк");
        if (weakWithoutDoc > 0) {
            summary.append(" · <font color=\"DarkOrange\">без «№ докум.»: ")
                    .append(weakWithoutDoc)
                    .append("</font> (счётчик; список — не в логе)");
        }
        log.line(summary.toString());
    }

    /**
     * Поиск ячейки «№ докум.» (точное совпадение после trim), первые 40 строк.
     *
     * @param sheet лист
     * @return [row, col] или empty
     */
    Optional<int[]> findAnchor(Sheet sheet) {
        int lastRow = Math.min(sheet.getLastRowNum(), 40);
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
                if (text != null && ANCHOR_DOC_NUM.equals(text.trim())) {
                    return Optional.of(new int[]{r, c});
                }
            }
        }
        return Optional.empty();
    }

    private boolean rowLooksLikePayment(Row row, int anchorCol) {
        if (notBlank(cellReader.readString(row.getCell(anchorCol + OFF_DOC_CODE)))) {
            return true;
        }
        if (notBlank(cellReader.readString(row.getCell(anchorCol + OFF_BE)))) {
            return true;
        }
        return softInt(row.getCell(anchorCol + OFF_ACCOUNT)) != null;
    }

    private SudzPmtUplTblRow mapRow(Row row, int anchorCol, int sheetNum, int unloadKey) {
        return new SudzPmtUplTblRow(
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_BE)), 50),
                softInt(row.getCell(anchorCol + OFF_ACCOUNT)),
                softInt(row.getCell(anchorCol + OFF_CTPT_NUM)),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_CTPT_NAME)), 255),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_CAC)), 50),
                softInt(row.getCell(anchorCol + OFF_AGENT_NUM)),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_AGENT_NAME)), 255),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_CN_NAME)), 255),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_LINK)), 255),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_CN_INV)), 255),
                toDateTime(cellReader.readDate(row.getCell(anchorCol + OFF_ENTRY))),
                toDateTime(cellReader.readDate(row.getCell(anchorCol + OFF_DOC_DATE))),
                toDateTime(cellReader.readDate(row.getCell(anchorCol + OFF_DUE))),
                softDecimal(row.getCell(anchorCol + OFF_DBT)),
                softDecimal(row.getCell(anchorCol + OFF_DBT_OVERD)),
                softDecimal(row.getCell(anchorCol + OFF_DBT_OVERD_NOT)),
                softDecimal(row.getCell(anchorCol + OFF_CDT)),
                softDecimal(row.getCell(anchorCol + OFF_CDT_OVERD)),
                softDecimal(row.getCell(anchorCol + OFF_CDT_OVERD_NOT)),
                softDecimal(row.getCell(anchorCol + OFF_BLNS)),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_DOC_CODE)), 50),
                toDateTime(cellReader.readDate(row.getCell(anchorCol + OFF_ALIGN))),
                toDateTime(cellReader.readDate(row.getCell(anchorCol + OFF_BASE))),
                softDecimal(row.getCell(anchorCol + OFF_DOC_SUM)),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_STORNO_REASON)), 255),
                truncate(cellReader.readString(row.getCell(anchorCol + OFF_STORNO_DOC)), 50),
                sheetNum,
                unloadKey
        );
    }

    private Integer softInt(Cell cell) {
        var result = cellReader.readIntResult(cell);
        return result.ok() ? result.value() : null;
    }

    private BigDecimal softDecimal(Cell cell) {
        var result = cellReader.readDecimalResult(cell);
        return result.ok() ? result.value() : null;
    }

    private static LocalDateTime toDateTime(LocalDate date) {
        return date == null ? null : LocalDateTime.of(date, LocalTime.MIDNIGHT);
    }

    private static boolean notBlank(String value) {
        return value != null && !value.isBlank();
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        if (value.length() <= max) {
            return value;
        }
        return value.substring(0, max);
    }
}
