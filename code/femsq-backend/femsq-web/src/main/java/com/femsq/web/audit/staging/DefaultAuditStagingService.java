package com.femsq.web.audit.staging;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.RaColMap;
import com.femsq.database.model.RaSheetConf;
import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditFile;
import com.femsq.web.audit.AuditLogEntry;
import com.femsq.web.audit.AuditLogLevel;
import com.femsq.web.audit.AuditLogScope;
import com.femsq.web.audit.excel.AuditExcelCellReader;
import com.femsq.web.audit.excel.AuditExcelColumnLocator;
import com.femsq.web.audit.excel.AuditExcelException;
import com.femsq.web.audit.excel.AuditExcelReader;
import com.femsq.web.audit.mapping.AuditColumnMappingRepository;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.OptionalInt;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.logging.Logger;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellReference;
import org.springframework.stereotype.Service;

/**
 * Реализация Stage 1 (Excel -> staging) на основе декларативного маппинга.
 */
@Service
public class DefaultAuditStagingService implements AuditStagingService {

    private static final Logger log = Logger.getLogger(DefaultAuditStagingService.class.getName());
    private static final int BATCH_SIZE = 200;
    private static final DateTimeFormatter RAIN_DATE_HUMAN =
            DateTimeFormatter.ofPattern("dd.MM.yyyy", Locale.forLanguageTag("ru-RU"));
    /** Цвета SCR-003-D / mapping (светлая тема). */
    private static final String HTML_TEAL_SIGN = "#007070";
    private static final String HTML_DARK_GREEN_TAIL = "#006400";
    private static final String HTML_ORANGE_ID = "#D06000";
    private static final String HTML_GRAY_NOTE = "#606060";
    private static final int FILTERED_SIGN_TOP_LIMIT = 5;
    private static final Set<String> TYPE5_ALLOWED_SIGNS = Set.of("оа", "оа изм", "оа прочие");
    /**
     * Логические колонки staging для описания вертикального диапазона на листе (аналог VBA {@code ra_RA} по ключевому столбцу).
     */
    private static final List<String> RANGE_ANCHOR_STAGING_COLUMNS = List.of(
            "rainRaNum",
            "rainSign",
            "rainCstAgPnStr"
    );

    private final AuditColumnMappingRepository mappingRepository;
    private final AuditExcelReader excelReader;
    private final AuditExcelColumnLocator columnLocator;
    private final AuditExcelCellReader cellReader;
    private final ConnectionFactory connectionFactory;

    public DefaultAuditStagingService(
            AuditColumnMappingRepository mappingRepository,
            AuditExcelReader excelReader,
            AuditExcelColumnLocator columnLocator,
            AuditExcelCellReader cellReader,
            ConnectionFactory connectionFactory
    ) {
        this.mappingRepository = Objects.requireNonNull(mappingRepository, "mappingRepository");
        this.excelReader = Objects.requireNonNull(excelReader, "excelReader");
        this.columnLocator = Objects.requireNonNull(columnLocator, "columnLocator");
        this.cellReader = Objects.requireNonNull(cellReader, "cellReader");
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
    }

    @Override
    public int loadToStaging(AuditExecutionContext context, AuditFile file) {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(file, "file");
        if (file.getType() == null) {
            throw new AuditExcelException("File type is required for staging load");
        }

        List<RaSheetConf> sheetConfigs = mappingRepository.getSheetConfigs(file.getType());
        if (sheetConfigs.isEmpty()) {
            log.info(() -> "[AuditStaging] No sheet config for file type=" + file.getType());
            return 0;
        }
        final boolean emitRowParagraphPreview = fileTypeSupportsRowParagraph(file);

        Instant openedAt = Instant.now();
        String workbookSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "WORKBOOK_OPEN",
                "<P>Книга открывается: " + escape(file.getPath()) + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "filePath", String.valueOf(file.getPath()),
                                "openedAt", String.valueOf(openedAt)
                        ),
                        "START",
                        "BLUE",
                        "BOLD"
                )
        );
        try {
            return context.inSpan(
                    workbookSpanId,
                    () -> excelReader.withWorkbook(file.getPath(), workbook -> loadWorkbook(context, workbook, sheetConfigs,
                            emitRowParagraphPreview))
            );
        } finally {
            Instant closedAt = Instant.now();
            context.endSpan(workbookSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "WORKBOOK_CLOSE",
                    "<P>Книга закрыта: " + escape(file.getPath()) + ". Duration: " + formatDuration(openedAt, closedAt) + "</P>",
                    withPresentationMeta(
                            Map.of(
                                    "auditId", String.valueOf(context.getAuditId()),
                                    "filePath", String.valueOf(file.getPath()),
                                    "closedAt", String.valueOf(closedAt),
                                    "durationHuman", formatDuration(openedAt, closedAt)
                            ),
                            "END",
                            "BLUE",
                            "BOLD"
                    ));
        }
    }

    private int loadWorkbook(AuditExecutionContext context,
                             Workbook workbook,
                             List<RaSheetConf> sheetConfigs,
                             boolean emitRowParagraphPreview) {
        int totalInserted = 0;
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                for (RaSheetConf config : sheetConfigs) {
                    Set<String> allowedSigns = resolveAllowedSigns(config, emitRowParagraphPreview);
                    totalInserted += loadSheet(context, connection, workbook, config, emitRowParagraphPreview, allowedSigns);
                }
                connection.commit();
            } catch (Exception exception) {
                connection.rollback();
                throw exception;
            }
        } catch (SQLException exception) {
            throw new AuditExcelException("Failed to load staging data: " + exception.getMessage(), exception);
        }
        return totalInserted;
    }

    private int loadSheet(AuditExecutionContext context,
                          Connection connection,
                          Workbook workbook,
                          RaSheetConf config,
                          boolean emitRowParagraphPreview,
                          Set<String> allowedSigns)
            throws SQLException {
        Instant stagingStartedAt = Instant.now();
        String stagingSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_START",
                "<P>Staging start: table=" + escape(config.rscStgTbl()) + ", sheet=" + escape(config.rscSheet()) + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "tableName", String.valueOf(config.rscStgTbl()),
                                "sheetName", String.valueOf(config.rscSheet())
                        ),
                        "START",
                        "BLUE",
                        "BOLD"
                )
        );
        Sheet sheet = resolveSheet(workbook, config.rscSheet());
        if (sheet == null) {
            context.append(AuditLogLevel.WARNING, AuditLogScope.FILE, "SHEET_MISSING",
                    "<P>Лист не найден: " + escape(config.rscSheet()) + "</P>",
                    withPresentationMeta(
                            Map.of(
                                    "auditId", String.valueOf(context.getAuditId()),
                                    "sheetName", String.valueOf(config.rscSheet()),
                                    "tableName", String.valueOf(config.rscStgTbl())
                            ),
                            "WARN",
                            "RED",
                            "BOLD"
                    ));
            throw new AuditExcelException("Sheet not found: " + config.rscSheet());
        }

        OptionalInt anchorRowOpt = columnLocator.findAnchorRow(sheet, config.rscAnchor(), config.rscAnchorMatch());
        if (anchorRowOpt.isEmpty()) {
            context.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "ANCHOR_MISSING",
                    "<P>Якорь не найден: " + escape(config.rscAnchor()) + ", лист=" + escape(sheet.getSheetName()) + "</P>",
                    withPresentationMeta(
                            Map.of(
                                    "auditId", String.valueOf(context.getAuditId()),
                                    "sheetName", String.valueOf(sheet.getSheetName()),
                                    "anchorText", String.valueOf(config.rscAnchor()),
                                    "tableName", String.valueOf(config.rscStgTbl())
                            ),
                            "WARN",
                            "RED",
                            "BOLD"
                    )
            );
            throw new AuditExcelException("Anchor not found: " + config.rscAnchor() + ", sheet=" + sheet.getSheetName());
        }
        String anchorColumnLabel = config.rscAnchor() == null || config.rscAnchor().isBlank()
                ? "(якорь)"
                : config.rscAnchor().trim();
        int anchorColumnOneBased = findAnchorColumnOneBased(sheet.getRow(anchorRowOpt.getAsInt()), config.rscAnchor());
        int anchorRowOneBased = anchorRowOpt.getAsInt() + 1;
        String anchorCellContent = readAnchorCellContent(sheet.getRow(anchorRowOpt.getAsInt()), anchorColumnOneBased);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "ANCHOR_FOUND",
                "<P>Найдена ячейка " + escape(anchorColumnLabel)
                        + " колонка - " + anchorColumnOneBased
                        + ", строка - " + anchorRowOneBased
                        + ". Содержание: " + escape(anchorCellContent) + ".</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "anchorText", String.valueOf(config.rscAnchor()),
                                "anchorRow", String.valueOf(anchorRowOpt.getAsInt()),
                                "anchorRowOneBased", String.valueOf(anchorRowOneBased),
                                "anchorColumn", String.valueOf(anchorColumnOneBased),
                                "anchorCellContent", String.valueOf(anchorCellContent),
                                "tableName", String.valueOf(config.rscStgTbl())
                        ),
                        "INFO",
                        "BLUE",
                        "NORMAL"
                )
        );

        int headerRowIndex = anchorRowOpt.getAsInt();
        Row headerRow = sheet.getRow(headerRowIndex);
        if (headerRow == null) {
            throw new AuditExcelException("Header row is missing at index " + headerRowIndex + ", sheet=" + sheet.getSheetName());
        }

        List<RaColMap> mappings = mappingRepository.getColumnMappings(config.rscKey());
        Map<String, Integer> excelColumns = columnLocator.locateColumns(headerRow, mappings);
        int rangeColumnIndex0 = resolveRangeColumnIndex0(excelColumns, mappings);
        SheetDataRangeSpec dataRange = buildSheetDataRangeSpec(sheet, headerRowIndex, rangeColumnIndex0);
        appendSheetFound(context, config, sheet, dataRange);
        Set<String> requiredColumns = mappings.stream()
                .filter(mapping -> Boolean.TRUE.equals(mapping.rcmRequired()))
                .map(RaColMap::rcmTblCol)
                .filter(excelColumns::containsKey)
                .collect(java.util.stream.Collectors.toSet());

        Map<String, Integer> dbColumnTypes = readColumnTypes(connection, config.rscStgTbl());
        Map<String, Integer> dbColumnSizes = readColumnSizes(connection, config.rscStgTbl());
        String execColumn = findExecColumn(dbColumnTypes.keySet());

        List<String> insertColumns = resolveInsertColumns(mappings, excelColumns, dbColumnTypes.keySet(), execColumn, context.getExecutionKey());
        if (insertColumns.isEmpty()) {
            return 0;
        }

        String insertSql = buildInsertSql(config.rscStgTbl(), insertColumns);
        int inserted = 0;
        int batchCount = 0;
        SheetLoadStats stats = new SheetLoadStats(sheet.getSheetName(), config.rscStgTbl(), headerRowIndex + 1, sheet.getLastRowNum());
        boolean logEachStagingRow = emitRowParagraphPreview;
        try (PreparedStatement statement = logEachStagingRow
                ? connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)
                : connection.prepareStatement(insertSql)) {
            for (int rowIndex = headerRowIndex + 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                stats.sourceRows++;
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    stats.skippedNullRow++;
                    continue;
                }
                if (allowedSigns != null) {
                    String signRaw = readStringByColumnName(row, excelColumns, "rainSign");
                    String normalizedSign = normalizeSign(signRaw);
                    if (!allowedSigns.contains(normalizedSign)) {
                        stats.filteredBySign++;
                        stats.filteredSignCounts.compute(safeSignLabel(signRaw), (k, v) -> v == null ? 1 : v + 1);
                        continue;
                    }
                    stats.acceptedBySign++;
                }
                RowBindOutcome outcome = bindRow(
                        statement,
                        row,
                        insertColumns,
                        excelColumns,
                        dbColumnTypes,
                        dbColumnSizes,
                        execColumn,
                        context.getExecutionKey(),
                        requiredColumns
                );
                if (!outcome.insertable()) {
                    if (outcome.missingRequiredData()) {
                        stats.skippedMissingRequired++;
                    } else {
                        stats.skippedNoBusinessData++;
                    }
                    if (emitRowParagraphPreview) {
                        stats.rowParagraphTotal++;
                        stats.rowParagraphSampled++;
                        String html = buildRowParagraphVbaHtml(row, excelColumns, rowIndex + 1, false, -1L);
                        context.append(
                                AuditLogLevel.WARNING,
                                AuditLogScope.FILE,
                                "ROW_PARAGRAPH_PREVIEW_SKIPPED",
                                "<P>" + html + "</P>",
                                withPresentationMeta(
                                        Map.of(
                                                "auditId", String.valueOf(context.getAuditId()),
                                                "sheetName", String.valueOf(sheet.getSheetName()),
                                                "rowIndex", String.valueOf(rowIndex + 1),
                                                "status", "SKIPPED"
                                        ),
                                        "WARN",
                                        "ORANGE",
                                        "NORMAL"
                                )
                        );
                    }
                    continue;
                }
                if (outcome.truncatedFields() > 0) {
                    stats.rowsWithTruncation++;
                    stats.totalTruncatedFields += outcome.truncatedFields();
                }
                stats.acceptedRows++;
                stats.acceptedSignCounts.compute(outcome.rainSign(), (k, v) -> v == null ? 1 : v + 1);
                if (logEachStagingRow) {
                    stats.rowParagraphTotal++;
                    statement.executeUpdate();
                    inserted++;
                    long rainKey = readGeneratedRainKey(statement);
                    appendStagingRowInserted(context, sheet, config, rowIndex + 1, rainKey);
                    stats.rowParagraphSampled++;
                    String html = buildRowParagraphVbaHtml(row, excelColumns, rowIndex + 1, true, rainKey);
                    context.append(
                            AuditLogLevel.INFO,
                            AuditLogScope.FILE,
                            "ROW_PARAGRAPH_PREVIEW",
                            "<P>" + html + "</P>",
                            withPresentationMeta(
                                    Map.of(
                                            "auditId", String.valueOf(context.getAuditId()),
                                            "sheetName", String.valueOf(sheet.getSheetName()),
                                            "rowIndex", String.valueOf(rowIndex + 1),
                                            "rainKey", String.valueOf(rainKey),
                                            "status", "ACCEPTED"
                                    ),
                                    "INFO",
                                    "TEAL",
                                    "NORMAL"
                            )
                    );
                } else {
                    statement.addBatch();
                    batchCount++;
                    if (batchCount >= BATCH_SIZE) {
                        inserted += executeBatch(statement);
                        batchCount = 0;
                    }
                }
            }
            if (!logEachStagingRow && batchCount > 0) {
                inserted += executeBatch(statement);
            }
        }
        stats.insertedRows = inserted;
        logSheetStats(context, stats);
        Instant stagingEndedAt = Instant.now();
        context.endSpan(stagingSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "STAGING_END",
                "<P>Staging end: table=" + escape(config.rscStgTbl()) + ", sheet=" + escape(sheet.getSheetName())
                        + ", inserted=" + inserted + ", duration=" + formatDuration(stagingStartedAt, stagingEndedAt) + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "tableName", String.valueOf(config.rscStgTbl()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "inserted", String.valueOf(inserted),
                                "durationHuman", formatDuration(stagingStartedAt, stagingEndedAt)
                        ),
                        "END",
                        "BLUE",
                        "BOLD"
                ));
        return inserted;
    }

    private void logSheetStats(AuditExecutionContext context, SheetLoadStats stats) {
        String signStats = formatSignStats(stats.acceptedSignCounts);
        String filteredSignsTop = formatTopN(stats.filteredSignCounts, FILTERED_SIGN_TOP_LIMIT);
        String message = "[AuditStaging] sheet=" + stats.sheetName
                + ", table=" + stats.stagingTable
                + ", rowRange=" + stats.firstDataRow + "-" + stats.lastDataRow
                + ", sourceRows=" + stats.sourceRows
                + ", acceptedBySign=" + stats.acceptedBySign
                + ", filteredBySign=" + stats.filteredBySign
                + ", filteredSignsTop=" + filteredSignsTop
                + ", inserted=" + stats.insertedRows
                + ", skippedNullRow=" + stats.skippedNullRow
                + ", skippedNoBusinessData=" + stats.skippedNoBusinessData
                + ", skippedMissingRequired=" + stats.skippedMissingRequired
                + ", rowsWithTruncation=" + stats.rowsWithTruncation
                + ", truncatedFields=" + stats.totalTruncatedFields
                + ", signStats=" + signStats;
        log.info(message);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_LOAD_STATS",
                "<P>" + message + "</P>",
                withPresentationMeta(
                        stagingStatsMeta(context, stats, filteredSignsTop),
                        "INFO",
                        "SILVER",
                        "NORMAL"
                )
        );
        if (stats.rowParagraphTotal > 0) {
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "ROW_PARAGRAPH_PREVIEW_SUMMARY",
                    "<P>Row-level staging: залогировано сообщений " + stats.rowParagraphSampled
                            + " по " + stats.rowParagraphTotal + " строкам (без лимита, полный вывод).</P>",
                    withPresentationMeta(
                            Map.of(
                                    "auditId", String.valueOf(context.getAuditId()),
                                    "sheetName", stats.sheetName,
                                    "sampled", String.valueOf(stats.rowParagraphSampled),
                                    "suppressed", String.valueOf(stats.rowParagraphSuppressed),
                                    "total", String.valueOf(stats.rowParagraphTotal),
                                    "previewMode", "FULL"
                            ),
                            "INFO",
                            "BLUE",
                            "NORMAL"
                    )
            );
        }
    }

    private boolean fileTypeSupportsRowParagraph(AuditFile file) {
        return file != null && Integer.valueOf(5).equals(file.getType());
    }

    /**
     * Текст строки лога staging в стиле VBA (SCR-003-D): тип (teal), хвост «Отчёт внесён…» (dark green), ID (orange).
     *
     * @param excelRowOneBased номер строки на листе Excel (1-based)
     * @param accepted         {@code false} — пропуск до insert; {@code true} — после успешного {@code INSERT}
     * @param rainKey          сгенерированный {@code rain_key} или {@code <= 0}, если не получен
     */
    /**
     * Событие {@code STAGING_ROW_INSERTED} (V-C.2.1.a.1.1.a.2.a.1 / 1.8.11.7.1): только после успешного {@code INSERT} и чтения {@code rain_key}.
     * При пакетной загрузке ({@code logEachStagingRow=false}) не вызывается — нет по-строчного {@code RETURN_GENERATED_KEYS}.
     */
    private void appendStagingRowInserted(
            AuditExecutionContext context,
            Sheet sheet,
            RaSheetConf config,
            int excelRowOneBased,
            long rainKey
    ) {
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.getAuditId()));
        meta.put("sheetName", String.valueOf(sheet.getSheetName()));
        meta.put("tableName", String.valueOf(config.rscStgTbl()));
        meta.put("rowIndex", String.valueOf(excelRowOneBased));
        meta.put("insertedId", String.valueOf(rainKey > 0 ? rainKey : 0));
        if (rainKey > 0) {
            String html = "<P><font color=\"" + HTML_DARK_GREEN_TAIL + "\">Добавлен в импорт. ID — </font>"
                    + "<b><font color=\"" + HTML_ORANGE_ID + "\">" + rainKey + "</font></b>"
                    + " <font color=\"" + HTML_GRAY_NOTE + "\">(строка листа Excel " + excelRowOneBased + ").</font></P>";
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "STAGING_ROW_INSERTED",
                    html,
                    withPresentationMeta(meta, "INFO", "GREEN", "NORMAL")
            );
        } else {
            String html = "<P><font color=\"#d29922\">INSERT в staging выполнен, идентификатор <code>rain_key</code> не получен от СУБД.</font> Строка листа "
                    + excelRowOneBased + ".</P>";
            context.append(
                    AuditLogLevel.WARNING,
                    AuditLogScope.FILE,
                    "STAGING_ROW_INSERTED",
                    html,
                    withPresentationMeta(meta, "WARN", "ORANGE", "NORMAL")
            );
        }
    }

    private String buildRowParagraphVbaHtml(
            Row row,
            Map<String, Integer> excelColumns,
            int excelRowOneBased,
            boolean accepted,
            long rainKey
    ) {
        String sign = readStringByColumnName(row, excelColumns, "rainSign");
        String raNum = readStringByColumnName(row, excelColumns, "rainRaNum");
        String cst = readStringByColumnName(row, excelColumns, "rainCstAgPnStr");
        if (sign == null || sign.isBlank()) {
            sign = "(тип не указан)";
        } else {
            sign = sign.trim();
        }
        if (raNum == null || raNum.isBlank()) {
            raNum = "(номер не указан)";
        } else {
            raNum = raNum.trim();
        }
        if (cst == null || cst.isBlank()) {
            cst = "(стройка не указана)";
        } else {
            cst = cst.trim();
        }
        String raDateLabel = formatRainRaDateForLog(row, excelColumns);
        StringBuilder sb = new StringBuilder();
        sb.append("Найден тип <b><font color=\"").append(HTML_TEAL_SIGN).append("\">*")
                .append(escape(sign)).append("*</font></b>");
        sb.append("; имя: ").append(escape(raNum));
        sb.append("; Стр. - ").append(escape(cst)).append(". ");
        sb.append("ОА ").append(escape(raNum)).append(" от ").append(raDateLabel).append(";");
        if (!accepted) {
            sb.append(" <font color=\"").append(HTML_GRAY_NOTE).append("\">— пропущено (нет достаточных данных)</font>");
        } else if (rainKey > 0) {
            sb.append(" <font color=\"").append(HTML_DARK_GREEN_TAIL).append("\">Отчёт внесён в промеж. тбл. ID - </font>");
            sb.append("<b><font color=\"").append(HTML_ORANGE_ID).append("\">").append(rainKey).append("</font></b>");
            sb.append(" <font color=\"").append(HTML_GRAY_NOTE).append("\">(строка листа Excel ")
                    .append(excelRowOneBased).append(").</font>");
        } else {
            sb.append(" <font color=\"").append(HTML_GRAY_NOTE).append("\">Отчёт внесён в промеж. тбл. (ключ строки не получен от СУБД). Строка листа ")
                    .append(excelRowOneBased).append(".</font>");
        }
        return sb.toString();
    }

    private String formatRainRaDateForLog(Row row, Map<String, Integer> excelColumns) {
        Integer idx = excelColumns.get("rainRaDate");
        if (idx == null) {
            return escape("(дата не указана)");
        }
        var cell = row.getCell(idx);
        if (cell == null) {
            return escape("(дата не указана)");
        }
        try {
            LocalDate d = cellReader.readDate(cell);
            if (d == null) {
                return escape("(дата не указана)");
            }
            return escape(RAIN_DATE_HUMAN.format(d));
        } catch (RuntimeException ex) {
            String raw = readStringByColumnName(row, excelColumns, "rainRaDate");
            if (raw != null && !raw.isBlank()) {
                return escape(raw.trim());
            }
            return escape("(дата не указана)");
        }
    }

    private static long readGeneratedRainKey(PreparedStatement statement) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (keys.next()) {
                return keys.getLong(1);
            }
        }
        return -1L;
    }

    private String readStringByColumnName(Row row, Map<String, Integer> excelColumns, String columnName) {
        Integer idx = excelColumns.get(columnName);
        if (idx == null) {
            return null;
        }
        return cellReader.readString(row.getCell(idx));
    }

    /**
     * Пишет событие {@code SHEET_FOUND} с координатами вертикального диапазона в ключевом столбце (SCR-003-C / VBA {@code ra_RA}).
     */
    private void appendSheetFound(
            AuditExecutionContext context,
            RaSheetConf config,
            Sheet sheet,
            SheetDataRangeSpec range
    ) {
        String sheetLabel = escape(sheet.getSheetName());
        String html = "<P>Найден диапазон <b><font color=\"blue\">" + sheetLabel + "</font></b>, колонка - "
                + range.columnOneBased()
                + ", первая строка - " + range.firstRowOneBased()
                + ", нижняя строка - " + range.lastRowOneBased()
                + ". Адрес: <font color=\"blue\">" + escape(range.address()) + "</font>.</P>";
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "SHEET_FOUND",
                html,
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "tableName", String.valueOf(config.rscStgTbl()),
                                "column", String.valueOf(range.columnOneBased()),
                                "firstRow", String.valueOf(range.firstRowOneBased()),
                                "lastRow", String.valueOf(range.lastRowOneBased()),
                                "address", String.valueOf(range.address())
                        ),
                        "INFO",
                        "BLUE",
                        "BOLD"
                )
        );
    }

    /**
     * Индекс колонки Excel (0-based) для описания диапазона данных (приоритет — ключевые бизнес-колонки staging).
     */
    private int resolveRangeColumnIndex0(Map<String, Integer> excelColumns, List<RaColMap> mappings) {
        for (String logical : RANGE_ANCHOR_STAGING_COLUMNS) {
            Integer idx = excelColumns.get(logical);
            if (idx != null && idx >= 0) {
                return idx;
            }
        }
        return mappings.stream()
                .filter(mapping -> Boolean.TRUE.equals(mapping.rcmRequired()))
                .sorted(Comparator.comparing(RaColMap::rcmTblColOrd))
                .map(m -> excelColumns.get(m.rcmTblCol()))
                .filter(Objects::nonNull)
                .findFirst()
                .orElseGet(() -> excelColumns.values().stream().min(Integer::compareTo).orElse(0));
    }

    /**
     * Вертикальный диапазон в одной колонке: от первой строки под заголовком до последней непустой ячейки (нумерация строк Excel, 1-based).
     */
    private SheetDataRangeSpec buildSheetDataRangeSpec(Sheet sheet, int headerRowIndex, int rangeColumnIndex0) {
        int firstDataRowIndex = headerRowIndex + 1;
        int firstRowOneBased = firstDataRowIndex + 1;
        String colLetters = CellReference.convertNumToColString(rangeColumnIndex0);
        int lastPoi = sheet.getLastRowNum();
        if (lastPoi < firstDataRowIndex) {
            String address = "$" + colLetters + "$" + firstRowOneBased + ":$" + colLetters + "$" + firstRowOneBased;
            return new SheetDataRangeSpec(rangeColumnIndex0 + 1, firstRowOneBased, firstRowOneBased, address);
        }
        int lastNonEmpty = -1;
        for (int r = lastPoi; r >= firstDataRowIndex; r--) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            if (cellReader.readString(row.getCell(rangeColumnIndex0)) != null) {
                lastNonEmpty = r;
                break;
            }
        }
        int lastRowOneBased = lastNonEmpty >= 0 ? lastNonEmpty + 1 : firstRowOneBased;
        String address = "$" + colLetters + "$" + firstRowOneBased + ":$" + colLetters + "$" + lastRowOneBased;
        return new SheetDataRangeSpec(rangeColumnIndex0 + 1, firstRowOneBased, lastRowOneBased, address);
    }

    /**
     * Координаты вертикального диапазона данных в столбце (метаданные для {@code SHEET_FOUND}).
     */
    private record SheetDataRangeSpec(int columnOneBased, int firstRowOneBased, int lastRowOneBased, String address) {
    }

    private int findAnchorColumnOneBased(Row anchorRow, String anchorText) {
        if (anchorRow == null || anchorText == null || anchorText.isBlank()) {
            return 0;
        }
        String expected = anchorText.trim();
        short last = anchorRow.getLastCellNum();
        if (last <= 0) {
            return 0;
        }
        for (int i = 0; i < last; i++) {
            String actual = cellReader.readString(anchorRow.getCell(i));
            if (actual == null) {
                continue;
            }
            if (expected.equalsIgnoreCase(actual.trim())) {
                return i + 1;
            }
        }
        return 0;
    }

    private String readAnchorCellContent(Row anchorRow, int anchorColumnOneBased) {
        if (anchorRow == null || anchorColumnOneBased <= 0) {
            return "";
        }
        String value = cellReader.readString(anchorRow.getCell(anchorColumnOneBased - 1));
        return value == null ? "" : value;
    }

    private String normalizeSign(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private String safeSignLabel(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "UNKNOWN_SIGN";
        }
        return value.trim();
    }

    private Set<String> resolveAllowedSigns(RaSheetConf config, boolean isType5) {
        if (!isType5) {
            return null;
        }
        if (config == null || config.rscSignWhitelist() == null || config.rscSignWhitelist().isBlank()) {
            return TYPE5_ALLOWED_SIGNS;
        }
        Set<String> configured = java.util.Arrays.stream(config.rscSignWhitelist().split("[,;\\n]+"))
                .map(this::normalizeSign)
                .filter(value -> !value.isBlank())
                .collect(Collectors.toCollection(LinkedHashSet::new));
        return configured.isEmpty() ? TYPE5_ALLOWED_SIGNS : configured;
    }

    private Map<String, String> withPresentationMeta(Map<String, String> meta,
                                                      String messageType,
                                                      String colorHint,
                                                      String emphasis) {
        Map<String, String> enriched = new HashMap<>();
        if (meta != null) {
            enriched.putAll(meta);
        }
        enriched.put("messageType", messageType);
        enriched.put("colorHint", colorHint);
        enriched.put("emphasis", emphasis);
        return enriched;
    }

    private String escape(String value) {
        return value == null ? "" : value.replace("<", "&lt;").replace(">", "&gt;");
    }

    private String formatDuration(Instant start, Instant end) {
        if (start == null || end == null) {
            return "-";
        }
        long seconds = ChronoUnit.SECONDS.between(start, end);
        if (seconds < 0) {
            seconds = 0;
        }
        long minutes = seconds / 60;
        long remSeconds = seconds % 60;
        return minutes + "m " + remSeconds + "s";
    }

    private String formatSignStats(Map<String, Integer> signCounts) {
        if (signCounts.isEmpty()) {
            return "{}";
        }
        StringBuilder builder = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Integer> entry : signCounts.entrySet()) {
            if (!first) {
                builder.append(", ");
            }
            first = false;
            builder.append(entry.getKey()).append("=").append(entry.getValue());
        }
        builder.append("}");
        return builder.toString();
    }

    private String formatTopN(Map<String, Integer> source, int limit) {
        if (source == null || source.isEmpty() || limit <= 0) {
            return "[]";
        }
        List<Map.Entry<String, Integer>> entries = source.entrySet().stream()
                .sorted((a, b) -> {
                    int byCount = Integer.compare(b.getValue(), a.getValue());
                    if (byCount != 0) {
                        return byCount;
                    }
                    return String.valueOf(a.getKey()).compareTo(String.valueOf(b.getKey()));
                })
                .limit(limit)
                .toList();
        StringBuilder builder = new StringBuilder("[");
        for (int i = 0; i < entries.size(); i++) {
            if (i > 0) {
                builder.append("; ");
            }
            Map.Entry<String, Integer> entry = entries.get(i);
            builder.append(entry.getKey()).append(" x").append(entry.getValue());
        }
        builder.append("]");
        return builder.toString();
    }

    private Map<String, String> stagingStatsMeta(AuditExecutionContext context, SheetLoadStats stats, String filteredSignsTop) {
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.getAuditId()));
        meta.put("sheet", stats.sheetName);
        meta.put("table", stats.stagingTable);
        meta.put("sourceRows", String.valueOf(stats.sourceRows));
        meta.put("acceptedBySign", String.valueOf(stats.acceptedBySign));
        meta.put("filteredBySign", String.valueOf(stats.filteredBySign));
        meta.put("filteredSignsTop", filteredSignsTop);
        meta.put("insertedRows", String.valueOf(stats.insertedRows));
        meta.put("rowParagraphSampled", String.valueOf(stats.rowParagraphSampled));
        meta.put("rowParagraphSuppressed", String.valueOf(stats.rowParagraphSuppressed));
        meta.put("rowParagraphTotal", String.valueOf(stats.rowParagraphTotal));
        return meta;
    }

    private Sheet resolveSheet(Workbook workbook, String sheetName) {
        if (sheetName == null || sheetName.isBlank()) {
            return workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
        }
        return workbook.getSheet(sheetName);
    }

    private Map<String, Integer> readColumnTypes(Connection connection, String tableName) throws SQLException {
        String[] parts = tableName.split("\\.");
        if (parts.length != 2) {
            throw new AuditExcelException("Unsupported table format: " + tableName);
        }
        Map<String, Integer> result = new HashMap<>();
        try (ResultSet rs = connection.getMetaData().getColumns(null, parts[0], parts[1], null)) {
            while (rs.next()) {
                String name = rs.getString("COLUMN_NAME");
                int jdbcType = rs.getInt("DATA_TYPE");
                result.put(name, jdbcType);
            }
        }
        return result;
    }

    private Map<String, Integer> readColumnSizes(Connection connection, String tableName) throws SQLException {
        String[] parts = tableName.split("\\.");
        if (parts.length != 2) {
            throw new AuditExcelException("Unsupported table format: " + tableName);
        }
        Map<String, Integer> result = new HashMap<>();
        try (ResultSet rs = connection.getMetaData().getColumns(null, parts[0], parts[1], null)) {
            while (rs.next()) {
                String name = rs.getString("COLUMN_NAME");
                int size = rs.getInt("COLUMN_SIZE");
                result.put(name, size);
            }
        }
        return result;
    }

    private String findExecColumn(Set<String> dbColumns) {
        return dbColumns.stream()
                .filter(col -> col.toLowerCase(Locale.ROOT).endsWith("_exec_key"))
                .findFirst()
                .orElse(null);
    }

    private List<String> resolveInsertColumns(
            List<RaColMap> mappings,
            Map<String, Integer> excelColumns,
            Set<String> dbColumns,
            String execColumn,
            Long executionKey
    ) {
        List<RaColMap> sorted = new ArrayList<>(mappings);
        sorted.sort(Comparator
                .comparing(RaColMap::rcmTblColOrd)
                .thenComparing(RaColMap::rcmXlHdrPri)
                .thenComparing(RaColMap::rcmKey));

        Set<String> columns = new LinkedHashSet<>();
        if (execColumn != null && executionKey != null) {
            columns.add(execColumn);
        }
        for (RaColMap mapping : sorted) {
            String stagingCol = mapping.rcmTblCol();
            if (excelColumns.containsKey(stagingCol) && dbColumns.contains(stagingCol)) {
                columns.add(stagingCol);
            }
        }
        return new ArrayList<>(columns);
    }

    private String buildInsertSql(String tableName, List<String> columns) {
        String cols = String.join(", ", columns);
        String placeholders = String.join(", ", columns.stream().map(c -> "?").toList());
        return "INSERT INTO " + tableName + " (" + cols + ") VALUES (" + placeholders + ")";
    }

    private RowBindOutcome bindRow(
            PreparedStatement statement,
            Row row,
            List<String> insertColumns,
            Map<String, Integer> excelColumns,
            Map<String, Integer> dbColumnTypes,
            Map<String, Integer> dbColumnSizes,
            String execColumn,
            Long executionKey,
            Set<String> requiredColumns
    ) throws SQLException {
        boolean hasBusinessData = false;
        boolean missingRequiredData = false;
        int truncatedFields = 0;
        String rainSign = "(null)";
        for (int i = 0; i < insertColumns.size(); i++) {
            String column = insertColumns.get(i);
            int jdbcType = dbColumnTypes.getOrDefault(column, Types.NVARCHAR);
            int parameterIndex = i + 1;
            if (execColumn != null && execColumn.equals(column)) {
                if (executionKey == null) {
                    statement.setNull(parameterIndex, Types.INTEGER);
                } else {
                    statement.setLong(parameterIndex, executionKey);
                }
                continue;
            }
            Integer excelColIndex = excelColumns.get(column);
            Object value = excelColIndex != null ? readTyped(row.getCell(excelColIndex), jdbcType) : null;
            if (value instanceof String stringValue) {
                Integer maxLength = dbColumnSizes.get(column);
                if (maxLength != null && maxLength > 0 && stringValue.length() > maxLength) {
                    value = stringValue.substring(0, maxLength);
                    truncatedFields++;
                }
            }
            if ("rainSign".equalsIgnoreCase(column) && value instanceof String stringValue && !stringValue.isBlank()) {
                rainSign = stringValue;
            }
            if (requiredColumns.contains(column) && isEmptyValue(value)) {
                missingRequiredData = true;
            }
            if (value != null) {
                hasBusinessData = true;
            }
            bindValue(statement, parameterIndex, jdbcType, value);
        }
        return new RowBindOutcome(hasBusinessData && !missingRequiredData, missingRequiredData, truncatedFields, rainSign);
    }

    private boolean isEmptyValue(Object value) {
        if (value == null) {
            return true;
        }
        if (value instanceof String stringValue) {
            return stringValue.trim().isEmpty();
        }
        return false;
    }

    private Object readTyped(org.apache.poi.ss.usermodel.Cell cell, int jdbcType) {
        return switch (jdbcType) {
            case Types.DATE -> cellReader.readDate(cell);
            case Types.INTEGER, Types.SMALLINT, Types.TINYINT, Types.BIGINT -> cellReader.readInt(cell);
            case Types.DECIMAL, Types.NUMERIC, Types.FLOAT, Types.DOUBLE, Types.REAL -> cellReader.readDecimal(cell);
            case Types.BIT, Types.BOOLEAN -> {
                Integer integerValue = cellReader.readInt(cell);
                yield integerValue == null ? null : integerValue != 0;
            }
            default -> cellReader.readString(cell);
        };
    }

    private void bindValue(PreparedStatement statement, int parameterIndex, int jdbcType, Object value) throws SQLException {
        if (value == null) {
            statement.setNull(parameterIndex, jdbcType);
            return;
        }
        switch (jdbcType) {
            case Types.DATE -> statement.setDate(parameterIndex, java.sql.Date.valueOf((LocalDate) value));
            case Types.INTEGER, Types.SMALLINT, Types.TINYINT -> statement.setInt(parameterIndex, ((Number) value).intValue());
            case Types.BIGINT -> statement.setLong(parameterIndex, ((Number) value).longValue());
            case Types.DECIMAL, Types.NUMERIC, Types.FLOAT, Types.DOUBLE, Types.REAL ->
                    statement.setBigDecimal(parameterIndex, value instanceof BigDecimal ? (BigDecimal) value : BigDecimal.valueOf(((Number) value).doubleValue()));
            case Types.BIT, Types.BOOLEAN -> statement.setBoolean(parameterIndex, (Boolean) value);
            default -> statement.setObject(parameterIndex, value);
        }
    }

    private int executeBatch(PreparedStatement statement) throws SQLException {
        int[] results = statement.executeBatch();
        int affected = 0;
        for (int value : results) {
            if (value > 0) {
                affected += value;
            }
        }
        return affected;
    }

    private record RowBindOutcome(boolean insertable, boolean missingRequiredData, int truncatedFields, String rainSign) {
    }

    private static final class SheetLoadStats {
        private final String sheetName;
        private final String stagingTable;
        private final int firstDataRow;
        private final int lastDataRow;
        private long sourceRows;
        private long acceptedBySign;
        private long filteredBySign;
        private long acceptedRows;
        private long insertedRows;
        private long skippedNullRow;
        private long skippedNoBusinessData;
        private long skippedMissingRequired;
        private long rowsWithTruncation;
        private long totalTruncatedFields;
        private final Map<String, Integer> acceptedSignCounts = new java.util.TreeMap<>();
        private final Map<String, Integer> filteredSignCounts = new java.util.TreeMap<>();
        private long rowParagraphSampled;
        private long rowParagraphSuppressed;
        private long rowParagraphTotal;

        private SheetLoadStats(String sheetName, String stagingTable, int firstDataRow, int lastDataRow) {
            this.sheetName = sheetName;
            this.stagingTable = stagingTable;
            this.firstDataRow = firstDataRow;
            this.lastDataRow = lastDataRow;
        }
    }
}
