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
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Component;

/**
 * Excel → {@code CnInvPmtUplTbl}: якорь «№ докум.» + колонки по ключевым словам заголовков.
 * <p>
 * VBA Access использовал фиксированные {@code Offset} от «№ докум.» (см. export_offset-map).
 * Выгрузки 26-0817 (счета 767501/767502) пришли с другим набором/порядком колонок —
 * Offset ломается. Разрешение по нормализованным ключевым словам покрывает канон QI
 * и новый layout; отсутствующие поля (срок оплаты, просрочки, баз.дата, сумма) → null.
 * </p>
 */
@Component
public class SudzPmtUplExcelToTblImporter {

    /** Точный заголовок якоря (xlWhole). */
    static final String ANCHOR_DOC_NUM = "№ докум.";

    /** Поля staging, сопоставляемые с заголовками. */
    enum Col {
        BE,
        ACCOUNT,
        CTPT_NUM,
        CTPT_NAME,
        CAC,
        AGENT_NUM,
        AGENT_NAME,
        CN_NAME,
        LINK,
        CN_INV,
        ENTRY,
        DOC_DATE,
        DUE,
        DBT,
        DBT_OVERD,
        DBT_OVERD_NOT,
        CDT,
        CDT_OVERD,
        CDT_OVERD_NOT,
        BLNS,
        DOC_CODE,
        ALIGN,
        BASE,
        DOC_SUM,
        STORNO_REASON,
        STORNO_DOC
    }

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
        int headerRowIdx = anchor.get()[0];
        int anchorCol = anchor.get()[1];
        Row headerRow = sheet.getRow(headerRowIdx);
        Map<Col, Integer> cols = resolveColumns(headerRow, anchorCol, log);
        if (!cols.containsKey(Col.DOC_CODE)) {
            log.line("<font color=\"red\">не разрешена колонка «№ докум.»</font>.");
            return;
        }
        if (!cols.containsKey(Col.BE) && !cols.containsKey(Col.ACCOUNT)) {
            log.line("<font color=\"red\">не найдены обязательные колонки БЕ / Счет ГК</font>"
                    + " по ключевым словам заголовков.");
            return;
        }

        int lastRow = sheet.getLastRowNum();
        int added = 0;
        int weakWithoutDoc = 0;
        for (int r = headerRowIdx + 1; r <= lastRow; r++) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            if (!rowLooksLikePayment(row, cols)) {
                continue;
            }
            String doc = cellString(row, cols, Col.DOC_CODE);
            if (!notBlank(doc)) {
                weakWithoutDoc++;
            }
            rows.add(mapRow(row, cols, sheetNum, unloadKey));
            added++;
        }

        StringBuilder summary = new StringBuilder();
        summary.append("лист <font color=\"Teal\"><b>")
                .append(SudzDbtUplProgressLog.escape(sheet.getSheetName()))
                .append("</b></font>: подготовлено <b>").append(added).append("</b> строк");
        summary.append(" · колонки по заголовкам (найдено ")
                .append(cols.size()).append("/").append(Col.values().length).append(")");
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

    /**
     * Нормализация заголовка: lower, ё→е, только буквы/цифры/№.
     *
     * @param raw заголовок
     * @return нормализованная строка
     */
    static String normalizeHeader(String raw) {
        if (raw == null) {
            return "";
        }
        String s = raw.trim().toLowerCase(Locale.ROOT).replace('ё', 'е');
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            if (Character.isLetterOrDigit(ch) || ch == '№') {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

    /**
     * Разрешает индексы колонок по ключевым словам строки заголовков.
     * Два «Агент» подряд → номер, затем имя (как VBA F/G).
     *
     * @param headerRow строка заголовков
     * @param anchorCol индекс «№ докум.»
     * @param log лог (предупреждения о пропусках)
     * @return карта Col → индекс колонки
     */
    Map<Col, Integer> resolveColumns(Row headerRow, int anchorCol, SudzDbtUplProgressLog log) {
        Map<Col, Integer> cols = new EnumMap<>(Col.class);
        cols.put(Col.DOC_CODE, anchorCol);

        short lastCell = headerRow == null ? -1 : headerRow.getLastCellNum();
        List<Integer> agentCols = new ArrayList<>();
        if (headerRow != null && lastCell > 0) {
            for (int c = 0; c < lastCell; c++) {
                if (c == anchorCol) {
                    continue;
                }
                String norm = normalizeHeader(cellReader.readString(headerRow.getCell(c)));
                if (norm.isEmpty()) {
                    continue;
                }
                if ("агент".equals(norm)) {
                    agentCols.add(c);
                    continue;
                }
                Col matched = matchSingle(norm);
                if (matched != null && !cols.containsKey(matched)) {
                    cols.put(matched, c);
                }
            }
        }
        if (!agentCols.isEmpty()) {
            cols.put(Col.AGENT_NUM, agentCols.get(0));
            if (agentCols.size() >= 2) {
                cols.put(Col.AGENT_NAME, agentCols.get(1));
            }
        }

        List<String> missing = new ArrayList<>();
        for (Col required : List.of(Col.BE, Col.ACCOUNT, Col.CTPT_NUM, Col.CTPT_NAME, Col.CN_NAME)) {
            if (!cols.containsKey(required)) {
                missing.add(required.name());
            }
        }
        if (!missing.isEmpty()) {
            log.line("<font color=\"DarkOrange\">заголовки не покрыли</font>: "
                    + SudzDbtUplProgressLog.escape(String.join(", ", missing))
                    + " (поля → null).");
        }
        return cols;
    }

    /**
     * Сопоставление одного нормализованного заголовка полю (кроме пары «Агент»).
     *
     * @param norm нормализованный заголовок
     * @return Col или null
     */
    static Col matchSingle(String norm) {
        if ("бе".equals(norm)) {
            return Col.BE;
        }
        if (norm.contains("счет") && norm.contains("гк")) {
            return Col.ACCOUNT;
        }
        if ("кредитор".equals(norm)) {
            return Col.CTPT_NUM;
        }
        if (norm.contains("наименован") && norm.contains("кредитор")) {
            return Col.CTPT_NAME;
        }
        if (norm.contains("код") && norm.contains("стройк")) {
            return Col.CAC;
        }
        if ("договор".equals(norm) || (norm.startsWith("договор") && !norm.contains("вид"))) {
            return Col.CN_NAME;
        }
        if (norm.contains("ссылк")) {
            return Col.LINK;
        }
        if (norm.contains("присвоен")) {
            return Col.CN_INV;
        }
        if (norm.contains("проводк")) {
            return Col.ENTRY;
        }
        // «Д/документ» / «ддокумент», не «№ докум.»
        if (norm.contains("ддокумент")
                || (norm.contains("документ") && norm.startsWith("д") && !norm.contains("№")
                && !norm.contains("сумм") && !norm.contains("сторн"))) {
            return Col.DOC_DATE;
        }
        if (norm.contains("срок") && norm.contains("оплат")) {
            return Col.DUE;
        }
        if (norm.contains("сальдо") && norm.contains("конечн") && !norm.contains("начальн")) {
            boolean overd = norm.contains("просроч");
            boolean notOverd = norm.contains("непросроч");
            boolean dt = norm.contains("дт");
            boolean kt = norm.contains("кт");
            if (dt && notOverd) {
                return Col.DBT_OVERD_NOT;
            }
            if (dt && overd) {
                return Col.DBT_OVERD;
            }
            if (kt && notOverd) {
                return Col.CDT_OVERD_NOT;
            }
            if (kt && overd) {
                return Col.CDT_OVERD;
            }
            if (dt && !kt) {
                return Col.DBT;
            }
            if (kt && (norm.contains("покт") || norm.contains("пок"))) {
                return Col.CDT;
            }
            if (kt) {
                return Col.CDT;
            }
            if (!dt && !kt && !overd) {
                return Col.BLNS;
            }
        }
        if (norm.contains("выравн") && !norm.contains("частичн")) {
            return Col.ALIGN;
        }
        if (norm.contains("баздат") || (norm.contains("баз") && norm.contains("дат"))) {
            return Col.BASE;
        }
        if (norm.contains("сумм") && norm.contains("документ")) {
            return Col.DOC_SUM;
        }
        if (norm.contains("прич") && norm.contains("сторн")) {
            return Col.STORNO_REASON;
        }
        if ((norm.contains("доксторн") || (norm.contains("док") && norm.contains("сторн")))
                && !norm.contains("прич")) {
            return Col.STORNO_DOC;
        }
        return null;
    }

    private boolean rowLooksLikePayment(Row row, Map<Col, Integer> cols) {
        if (notBlank(cellString(row, cols, Col.DOC_CODE))) {
            return true;
        }
        if (notBlank(cellString(row, cols, Col.BE))) {
            return true;
        }
        return softInt(cellAt(row, cols, Col.ACCOUNT)) != null;
    }

    private SudzPmtUplTblRow mapRow(Row row, Map<Col, Integer> cols, int sheetNum, int unloadKey) {
        return new SudzPmtUplTblRow(
                truncate(cellString(row, cols, Col.BE), 50),
                softInt(cellAt(row, cols, Col.ACCOUNT)),
                softInt(cellAt(row, cols, Col.CTPT_NUM)),
                truncate(cellString(row, cols, Col.CTPT_NAME), 255),
                truncate(cellString(row, cols, Col.CAC), 50),
                softInt(cellAt(row, cols, Col.AGENT_NUM)),
                truncate(cellString(row, cols, Col.AGENT_NAME), 255),
                truncate(cellString(row, cols, Col.CN_NAME), 255),
                truncate(cellString(row, cols, Col.LINK), 255),
                truncate(cellString(row, cols, Col.CN_INV), 255),
                toDateTime(cellReader.readDate(cellAt(row, cols, Col.ENTRY))),
                toDateTime(cellReader.readDate(cellAt(row, cols, Col.DOC_DATE))),
                toDateTime(cellReader.readDate(cellAt(row, cols, Col.DUE))),
                softDecimal(cellAt(row, cols, Col.DBT)),
                softDecimal(cellAt(row, cols, Col.DBT_OVERD)),
                softDecimal(cellAt(row, cols, Col.DBT_OVERD_NOT)),
                softDecimal(cellAt(row, cols, Col.CDT)),
                softDecimal(cellAt(row, cols, Col.CDT_OVERD)),
                softDecimal(cellAt(row, cols, Col.CDT_OVERD_NOT)),
                softDecimal(cellAt(row, cols, Col.BLNS)),
                truncate(cellString(row, cols, Col.DOC_CODE), 50),
                toDateTime(cellReader.readDate(cellAt(row, cols, Col.ALIGN))),
                toDateTime(cellReader.readDate(cellAt(row, cols, Col.BASE))),
                softDecimal(cellAt(row, cols, Col.DOC_SUM)),
                truncate(cellString(row, cols, Col.STORNO_REASON), 255),
                truncate(cellString(row, cols, Col.STORNO_DOC), 50),
                sheetNum,
                unloadKey
        );
    }

    private Cell cellAt(Row row, Map<Col, Integer> cols, Col col) {
        Integer idx = cols.get(col);
        if (idx == null || row == null) {
            return null;
        }
        return row.getCell(idx);
    }

    private String cellString(Row row, Map<Col, Integer> cols, Col col) {
        return cellReader.readString(cellAt(row, cols, col));
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
