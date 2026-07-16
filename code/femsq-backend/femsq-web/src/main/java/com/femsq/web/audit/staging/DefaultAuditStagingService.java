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
import com.femsq.web.audit.excel.CellReadResult;
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
    /**
     * Максимум поштучных WARN для OTHER type=5 (внутри диапазона + хвост); остаток — одной строкой.
     */
    private static final int TYPE5_OTHER_DETAIL_LIMIT = 40;
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
    private final AuditStagingProperties auditStagingProperties;

    public DefaultAuditStagingService(
            AuditColumnMappingRepository mappingRepository,
            AuditExcelReader excelReader,
            AuditExcelColumnLocator columnLocator,
            AuditExcelCellReader cellReader,
            ConnectionFactory connectionFactory,
            AuditStagingProperties auditStagingProperties
    ) {
        this.mappingRepository = Objects.requireNonNull(mappingRepository, "mappingRepository");
        this.excelReader = Objects.requireNonNull(excelReader, "excelReader");
        this.columnLocator = Objects.requireNonNull(columnLocator, "columnLocator");
        this.cellReader = Objects.requireNonNull(cellReader, "cellReader");
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        this.auditStagingProperties = Objects.requireNonNull(auditStagingProperties, "auditStagingProperties");
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
        final StagingLogLevel stagingLogLevel = resolveStagingLogLevel(context);
        final boolean isType5 = Integer.valueOf(5).equals(file.getType());

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
                            stagingLogLevel, isType5))
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
                             StagingLogLevel stagingLogLevel,
                             boolean isType5) {
        int totalInserted = 0;
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                for (RaSheetConf config : sheetConfigs) {
                    Set<String> allowedSigns = resolveAllowedSigns(config, isType5);
                    totalInserted += loadSheet(context, connection, workbook, config, stagingLogLevel, allowedSigns);
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
                          StagingLogLevel stagingLogLevel,
                          Set<String> allowedSigns)
            throws SQLException {
        Instant stagingStartedAt = Instant.now();
        String stagingSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_START",
                "<P>Начало загрузки в промежуточную таблицу: таблица = " + escape(friendlyStagingTable(config.rscStgTbl()))
                        + ", лист = «" + escape(config.rscSheet()) + "»</P>",
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
        java.util.regex.Pattern type5RaNumPattern = allowedSigns != null
                ? Type5SignFilterClassifier.compileRaNumPattern(
                        auditStagingProperties.getType5().getRaNumRegex())
                : null;
        SheetDataRangeSpec dataRange = buildSheetDataRangeSpec(
                sheet, headerRowIndex, rangeColumnIndex0, excelColumns, allowedSigns, type5RaNumPattern);
        appendSheetFound(context, config, sheet, dataRange);
        Set<String> requiredColumns = mappings.stream()
                .filter(mapping -> Boolean.TRUE.equals(mapping.rcmRequired()))
                .map(RaColMap::rcmTblCol)
                .filter(excelColumns::containsKey)
                .collect(java.util.stream.Collectors.toSet());
        Map<String, String> columnExcelHeaders = buildColumnExcelHeaders(mappings, excelColumns);

        Map<String, Integer> dbColumnTypes = readColumnTypes(connection, config.rscStgTbl());
        Map<String, Integer> dbColumnSizes = readColumnSizes(connection, config.rscStgTbl());
        String execColumn = findExecColumn(dbColumnTypes.keySet());
        String excelRowColumn = StagingExcelRowColumns.find(dbColumnTypes.keySet());

        List<String> insertColumns = resolveInsertColumns(
                mappings,
                excelColumns,
                dbColumnTypes.keySet(),
                execColumn,
                context.getExecutionKey(),
                excelRowColumn
        );
        if (insertColumns.isEmpty()) {
            return 0;
        }

        String insertSql = buildInsertSql(config.rscStgTbl(), insertColumns);
        int inserted = 0;
        int batchCount = 0;
        int firstDataRowIndex0 = headerRowIndex + 1;
        int lastDataRowIndex0 = Math.max(firstDataRowIndex0 - 1, dataRange.lastRowOneBased() - 1);
        int poiLastRowIndex0 = sheet.getLastRowNum();
        int beyondRangeRows = Math.max(0, poiLastRowIndex0 - lastDataRowIndex0);
        SheetLoadStats stats = new SheetLoadStats(
                sheet.getSheetName(),
                config.rscStgTbl(),
                dataRange.firstRowOneBased(),
                dataRange.lastRowOneBased()
        );
        stats.skippedBeyondRange = beyondRangeRows;
        boolean logEachStagingRow = stagingLogLevel.logEachStagingRow();
        boolean emitRowParagraphPreview = stagingLogLevel.emitRowParagraphPreview();
        boolean emitSummaryProgress = stagingLogLevel.emitSummaryProgress();
        boolean emitParseIssueLog = stagingLogLevel != StagingLogLevel.MINIMAL;
        int summaryProgressInterval = stagingLogLevel.summaryProgressInterval();
        // Накопитель пустых строк → одно INFO SUMMARY вместо тысяч ⚠.
        EmptyRowSkipBatch emptyRowSkipBatch = new EmptyRowSkipBatch();
        try (PreparedStatement statement = logEachStagingRow
                ? connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)
                : connection.prepareStatement(insertSql)) {
            for (int rowIndex = firstDataRowIndex0; rowIndex <= lastDataRowIndex0; rowIndex++) {
                stats.sourceRows++;
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    stats.skippedNullRow++;
                    if (emitSummaryProgress && !emitRowParagraphPreview) {
                        emptyRowSkipBatch.add(rowIndex + 1);
                    }
                    continue;
                }
                if (allowedSigns != null) {
                    String signRaw = readStringByColumnName(row, excelColumns, "rainSign");
                    String raNumRaw = readStringByColumnName(row, excelColumns, "rainRaNum");
                    Type5SignFilterClassifier.Decision signDecision =
                            Type5SignFilterClassifier.classify(signRaw, raNumRaw, allowedSigns);
                    if (signDecision.kind() == Type5SignFilterClassifier.Kind.EMPTY) {
                        // Пустой резерв / нет № и признака — не UNKNOWN_SIGN в топе фильтра.
                        stats.skippedEmptyBeforeSign++;
                        if (emitSummaryProgress && !emitRowParagraphPreview) {
                            emptyRowSkipBatch.add(rowIndex + 1);
                        }
                        continue;
                    }
                    if (signDecision.kind() == Type5SignFilterClassifier.Kind.FILTERED_ARENDA
                            || signDecision.kind() == Type5SignFilterClassifier.Kind.FILTERED_OTHER) {
                        flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
                        stats.filteredBySign++;
                        if (signDecision.kind() == Type5SignFilterClassifier.Kind.FILTERED_ARENDA) {
                            stats.filteredArendaBySign++;
                        }
                        String label = signDecision.label() != null
                                ? signDecision.label()
                                : Type5SignFilterClassifier.UNKNOWN_SIGN_LABEL;
                        stats.filteredSignCounts.compute(label, (k, v) -> v == null ? 1 : v + 1);
                        if (type5RaNumPattern != null
                                && Type5SignFilterClassifier.isOtherWithoutRaNumMarker(
                                        signDecision, raNumRaw, type5RaNumPattern)) {
                            recordType5OtherRow(
                                    context,
                                    sheet,
                                    rowIndex + 1,
                                    signRaw,
                                    raNumRaw,
                                    stats,
                                    emitParseIssueLog
                            );
                        }
                        continue;
                    }
                    stats.acceptedBySign++;
                }
                RowBindOutcome outcome = bindRow(
                        statement,
                        row,
                        insertColumns,
                        excelColumns,
                        columnExcelHeaders,
                        dbColumnTypes,
                        dbColumnSizes,
                        execColumn,
                        context.getExecutionKey(),
                        excelRowColumn,
                        rowIndex + 1,
                        requiredColumns
                );
                if (!outcome.insertable()) {
                    // Пустая строка (null Excel-row уже выше): без бизнес-данных — не «ошибка обязательных полей».
                    if (outcome.skippedDueToRequiredParseError()) {
                        stats.skippedParseError++;
                    } else if (!outcome.hasBusinessData()) {
                        stats.skippedNoBusinessData++;
                    } else if (outcome.missingRequiredData()) {
                        stats.skippedMissingRequired++;
                    } else {
                        stats.skippedNoBusinessData++;
                    }
                    boolean loggedParseIssues = emitParseIssueLog && !outcome.parseIssues().isEmpty();
                    if (loggedParseIssues) {
                        flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
                        appendStagingRowParseIssues(context, sheet, rowIndex + 1, outcome.parseIssues());
                    }
                    if (emitRowParagraphPreview) {
                        flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
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
                    } else if (emitSummaryProgress) {
                        boolean emptyLike = !outcome.hasBusinessData() && !outcome.skippedDueToRequiredParseError();
                        if (emptyLike && !loggedParseIssues) {
                            emptyRowSkipBatch.add(rowIndex + 1);
                        } else if (!emptyLike) {
                            flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
                            String reason = resolveSummarySkipReason(outcome, columnExcelHeaders);
                            if (reason != null) {
                                appendSummaryIssue(context, sheet, rowIndex + 1, reason);
                            }
                        }
                    }
                    continue;
                }
                flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
                if (outcome.optionalParseErrorFields() > 0) {
                    stats.parseErrorFields += outcome.optionalParseErrorFields();
                }
                if (emitParseIssueLog && !outcome.parseIssues().isEmpty()) {
                    appendStagingRowParseIssues(context, sheet, rowIndex + 1, outcome.parseIssues());
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
                    if (inserted % 50 == 0) {
                        int excelRowOneBased = rowIndex + 1;
                        int insertedSnapshot = inserted;
                        log.info(() -> "[AuditStaging] progress auditId=" + context.getAuditId()
                                + " sheet=" + sheet.getSheetName()
                                + " excelRow=" + excelRowOneBased
                                + " inserted=" + insertedSnapshot);
                    }
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
                    if (emitSummaryProgress && stats.sourceRows % summaryProgressInterval == 0) {
                        appendSummaryProgress(context, sheet, rowIndex + 1, inserted);
                    }
                    if (stats.sourceRows % 200 == 0) {
                        int excelRowOneBased = rowIndex + 1;
                        int insertedSnapshot = inserted;
                        log.info(() -> "[AuditStaging] progress auditId=" + context.getAuditId()
                                + " sheet=" + sheet.getSheetName()
                                + " excelRow=" + excelRowOneBased
                                + " inserted=" + insertedSnapshot
                                + " (batch mode)");
                    }
                    if (batchCount >= BATCH_SIZE) {
                        inserted += executeBatch(statement);
                        batchCount = 0;
                    }
                }
            }
            if (!logEachStagingRow && batchCount > 0) {
                inserted += executeBatch(statement);
            }
            flushEmptyRowSkipBatch(context, sheet, emptyRowSkipBatch);
        }
        if (allowedSigns != null && type5RaNumPattern != null && stagingLogLevel != StagingLogLevel.MINIMAL) {
            scanType5OtherBeyondRange(
                    context,
                    sheet,
                    lastDataRowIndex0,
                    poiLastRowIndex0,
                    excelColumns,
                    allowedSigns,
                    type5RaNumPattern,
                    stats,
                    emitParseIssueLog
            );
        }
        if (beyondRangeRows > 0 && stagingLogLevel != StagingLogLevel.MINIMAL) {
            appendBeyondDataRangeInfo(context, sheet, dataRange, beyondRangeRows);
        }
        stats.insertedRows = inserted;
        logSheetStats(context, stats, stagingLogLevel);
        appendType5OtherOverflowIfNeeded(context, sheet, stats, stagingLogLevel);
        Instant stagingEndedAt = Instant.now();
        context.endSpan(stagingSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "STAGING_END",
                "<P>Завершение загрузки в промежуточную таблицу: таблица = " + escape(friendlyStagingTable(config.rscStgTbl()))
                        + ", лист = «" + escape(sheet.getSheetName()) + "»"
                        + ", добавлено = " + inserted
                        + ", длительность = " + formatDuration(stagingStartedAt, stagingEndedAt) + "</P>",
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

    private void logSheetStats(AuditExecutionContext context, SheetLoadStats stats, StagingLogLevel stagingLogLevel) {
        String signStats = formatSignStats(stats.acceptedSignCounts);
        String filteredSignsTop = formatTopN(stats.filteredSignCounts, FILTERED_SIGN_TOP_LIMIT);
        long emptySkippedTotal = stats.skippedNullRow + stats.skippedEmptyBeforeSign;
        String techMessage = "[AuditStaging] sheet=" + stats.sheetName
                + ", table=" + stats.stagingTable
                + ", rowRange=" + stats.firstDataRow + "-" + stats.lastDataRow
                + ", sourceRows=" + stats.sourceRows
                + ", acceptedBySign=" + stats.acceptedBySign
                + ", filteredBySign=" + stats.filteredBySign
                + ", filteredArendaBySign=" + stats.filteredArendaBySign
                + ", filteredOtherWithoutMarker=" + stats.filteredOtherWithoutMarker
                + ", filteredSignsTop=" + filteredSignsTop
                + ", inserted=" + stats.insertedRows
                + ", skippedNullRow=" + stats.skippedNullRow
                + ", skippedEmptyBeforeSign=" + stats.skippedEmptyBeforeSign
                + ", skippedNoBusinessData=" + stats.skippedNoBusinessData
                + ", skippedMissingRequired=" + stats.skippedMissingRequired
                + ", skippedBeyondRange=" + stats.skippedBeyondRange
                + ", parseErrorFields=" + stats.parseErrorFields
                + ", skippedParseError=" + stats.skippedParseError
                + ", rowsWithTruncation=" + stats.rowsWithTruncation
                + ", truncatedFields=" + stats.totalTruncatedFields
                + ", signStats=" + signStats;
        log.info(techMessage);
        String humanMessage = "[Загрузка промежуточной таблицы] лист = «" + stats.sheetName + "»"
                + ", таблица = " + friendlyStagingTable(stats.stagingTable)
                + ", диапазон строк = " + stats.firstDataRow + "–" + stats.lastDataRow
                + ", строк в диапазоне = " + stats.sourceRows
                + ", принято по типу = " + stats.acceptedBySign
                + ", отфильтровано по типу = " + stats.filteredBySign
                + ", исключено по признаку «ОА Аренда» = " + stats.filteredArendaBySign
                + ", прочих без маркера № = " + stats.filteredOtherWithoutMarker
                + ", топ отфильтрованных типов = " + filteredSignsTop
                + ", добавлено = " + stats.insertedRows
                + ", пропущено пустых строк = " + emptySkippedTotal
                + ", пропущено без бизнес-данных = " + stats.skippedNoBusinessData
                + ", пропущено без обязательных полей = " + stats.skippedMissingRequired
                + ", за пределами диапазона = " + stats.skippedBeyondRange
                + ", ошибок формата полей = " + stats.parseErrorFields
                + ", пропущено из‑за ошибки формата = " + stats.skippedParseError
                + ", строк с усечением = " + stats.rowsWithTruncation
                + ", усечённых полей = " + stats.totalTruncatedFields
                + ", статистика по типам = " + signStats;
        if (stagingLogLevel != StagingLogLevel.MINIMAL) {
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "STAGING_LOAD_STATS",
                    "<P>" + escape(humanMessage) + "</P>",
                    withPresentationMeta(
                            stagingStatsMeta(context, stats, filteredSignsTop),
                            "INFO",
                            "SILVER",
                            "NORMAL"
                    )
            );
        } else {
            String minimalHtml = "<P>Итог, лист «" + escape(stats.sheetName) + "»: строк в диапазоне = "
                    + stats.sourceRows + ", добавлено = " + stats.insertedRows
                    + ", пропущено (нет данных) = "
                    + (stats.skippedNullRow + stats.skippedEmptyBeforeSign
                    + stats.skippedNoBusinessData + stats.skippedMissingRequired)
                    + ", исключено «ОА Аренда» = " + stats.filteredArendaBySign
                    + ", прочих без маркера № = " + stats.filteredOtherWithoutMarker
                    + ", за пределами диапазона = " + stats.skippedBeyondRange
                    + ", ошибки формата (поля NULL) = " + stats.parseErrorFields
                    + ", пропущено (обязат. поле, формат) = " + stats.skippedParseError
                    + ".</P>";
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "STAGING_LOAD_STATS",
                    minimalHtml,
                    withPresentationMeta(
                            stagingStatsMeta(context, stats, filteredSignsTop),
                            "INFO",
                            "SILVER",
                            "NORMAL"
                    )
            );
        }
        if (stats.rowParagraphTotal > 0) {
            context.append(
                    AuditLogLevel.INFO,
                    AuditLogScope.FILE,
                    "ROW_PARAGRAPH_PREVIEW_SUMMARY",
                    "<P>Подробный лог строк staging: залогировано сообщений " + stats.rowParagraphSampled
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

    /**
     * Сообщает, что хвост листа за найденным диапазоном не разбирался.
     */
    private void appendBeyondDataRangeInfo(
            AuditExecutionContext context,
            Sheet sheet,
            SheetDataRangeSpec range,
            int beyondRangeRows
    ) {
        String text = StagingRowSkipReasonFormatter.formatBeyondDataRange(
                range.address(),
                range.lastRowOneBased(),
                beyondRangeRows
        );
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_BEYOND_DATA_RANGE",
                "<P>" + escape(text) + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "address", String.valueOf(range.address()),
                                "lastRow", String.valueOf(range.lastRowOneBased()),
                                "beyondRows", String.valueOf(beyondRangeRows)
                        ),
                        "INFO",
                        "SILVER",
                        "NORMAL"
                )
        );
    }

    /**
     * Сканирует хвост листа за нижней границей диапазона на OTHER без маркера № ОА.
     */
    private void scanType5OtherBeyondRange(
            AuditExecutionContext context,
            Sheet sheet,
            int lastDataRowIndex0,
            int poiLastRowIndex0,
            Map<String, Integer> excelColumns,
            Set<String> allowedSigns,
            java.util.regex.Pattern type5RaNumPattern,
            SheetLoadStats stats,
            boolean emitDetail
    ) {
        for (int rowIndex = lastDataRowIndex0 + 1; rowIndex <= poiLastRowIndex0; rowIndex++) {
            Row row = sheet.getRow(rowIndex);
            if (row == null) {
                continue;
            }
            String signRaw = readStringByColumnName(row, excelColumns, "rainSign");
            String raNumRaw = readStringByColumnName(row, excelColumns, "rainRaNum");
            Type5SignFilterClassifier.Decision decision =
                    Type5SignFilterClassifier.classify(signRaw, raNumRaw, allowedSigns);
            if (Type5SignFilterClassifier.isOtherWithoutRaNumMarker(
                    decision, raNumRaw, type5RaNumPattern)) {
                recordType5OtherRow(
                        context, sheet, rowIndex + 1, signRaw, raNumRaw, stats, emitDetail);
            }
        }
    }

    /**
     * Учитывает OTHER type=5 и при необходимости пишет поштучный WARN (лимит топа).
     */
    private void recordType5OtherRow(
            AuditExecutionContext context,
            Sheet sheet,
            int excelRowOneBased,
            String signRaw,
            String raNumRaw,
            SheetLoadStats stats,
            boolean emitDetail
    ) {
        stats.filteredOtherWithoutMarker++;
        if (!emitDetail || stats.filteredOtherDetailsLogged >= TYPE5_OTHER_DETAIL_LIMIT) {
            return;
        }
        String reason = StagingRowSkipReasonFormatter.formatType5OtherWithoutMarker(signRaw, raNumRaw);
        context.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "STAGING_TYPE5_OTHER",
                "<P>⚠ Excel-строка " + excelRowOneBased + ": " + escape(reason) + ".</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "rowIndex", String.valueOf(excelRowOneBased),
                                "reason", reason,
                                "sign", signRaw == null ? "" : signRaw,
                                "raNum", raNumRaw == null ? "" : raNumRaw
                        ),
                        "WARN",
                        "ORANGE",
                        "NORMAL"
                )
        );
        stats.filteredOtherDetailsLogged++;
    }

    /**
     * Пишет INFO, если OTHER больше лимита поштучных WARN.
     */
    private void appendType5OtherOverflowIfNeeded(
            AuditExecutionContext context,
            Sheet sheet,
            SheetLoadStats stats,
            StagingLogLevel stagingLogLevel
    ) {
        if (stagingLogLevel == StagingLogLevel.MINIMAL) {
            return;
        }
        long remaining = stats.filteredOtherWithoutMarker - stats.filteredOtherDetailsLogged;
        if (remaining <= 0) {
            return;
        }
        String text = StagingRowSkipReasonFormatter.formatType5OtherOverflow((int) remaining);
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_TYPE5_OTHER_OVERFLOW",
                "<P>" + escape(text) + ".</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "remaining", String.valueOf(remaining),
                                "logged", String.valueOf(stats.filteredOtherDetailsLogged),
                                "total", String.valueOf(stats.filteredOtherWithoutMarker)
                        ),
                        "INFO",
                        "SILVER",
                        "NORMAL"
                )
        );
    }

    /**
     * Краткое имя staging-таблицы для пользовательского лога.
     */
    private String friendlyStagingTable(String tableName) {
        if (tableName == null || tableName.isBlank()) {
            return "(таблица не указана)";
        }
        return switch (tableName.trim().toLowerCase(Locale.ROOT)) {
            case "ags.ra_stg_ra" -> "промежуточная РА";
            case "ags.ra_stg_cn_prdoc" -> "промежуточная CN_PrDoc";
            case "ags.ra_stg_ralp" -> "промежуточная RALP";
            case "ags.ra_stg_ralp_sm" -> "промежуточная RALP_SM";
            case "ags.ra_stg_agfee" -> "промежуточная AgFee";
            default -> tableName;
        };
    }

    private StagingLogLevel resolveStagingLogLevel(AuditExecutionContext context) {
        if (context.getStagingLogLevel() != null) {
            return context.getStagingLogLevel();
        }
        return auditStagingProperties.getDefaultLogLevel();
    }

    private void appendSummaryProgress(AuditExecutionContext context, Sheet sheet, int excelRowOneBased, int inserted) {
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_PROGRESS",
                "<P>Прогресс: Excel-строка " + excelRowOneBased + " — внесено в промежуточную таблицу: " + inserted + "</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "rowIndex", String.valueOf(excelRowOneBased),
                                "inserted", String.valueOf(inserted)
                        ),
                        "INFO",
                        "BLUE",
                        "NORMAL"
                )
        );
    }

    private void appendStagingRowParseIssues(
            AuditExecutionContext context,
            Sheet sheet,
            int excelRowOneBased,
            List<CellParseIssue> issues
    ) {
        if (issues == null || issues.isEmpty()) {
            return;
        }
        StringBuilder html = new StringBuilder();
        html.append("<P>⚠ Excel-строка ").append(excelRowOneBased)
                .append(", лист «").append(escape(sheet.getSheetName())).append("»:");
        String rowAction = "ПРИНЯТА_NULL";
        for (CellParseIssue issue : issues) {
            html.append("<br/>  колонка ").append(escape(issue.column()))
                    .append(" («").append(escape(issue.excelHeader())).append("»): ожидается ")
                    .append(escape(issue.expectedType())).append(", получено «")
                    .append(escape(issue.rawValue())).append("» — ");
            if (issue.required()) {
                html.append("строка пропущена.");
                rowAction = "ПРОПУЩЕНА";
            } else {
                html.append("строка принята, поле записано как NULL.");
            }
        }
        html.append("</P>");
        Map<String, String> meta = new HashMap<>();
        meta.put("auditId", String.valueOf(context.getAuditId()));
        meta.put("sheetName", String.valueOf(sheet.getSheetName()));
        meta.put("rowIndex", String.valueOf(excelRowOneBased));
        meta.put("rowAction", rowAction);
        context.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "STAGING_ROW_ISSUE",
                html.toString(),
                withPresentationMeta(meta, "WARN", "ORANGE", "NORMAL")
        );
    }

    private String resolveSummarySkipReason(RowBindOutcome outcome, Map<String, String> columnExcelHeaders) {
        if (outcome.skippedDueToRequiredParseError()) {
            return null;
        }
        if (!outcome.hasBusinessData()) {
            return null;
        }
        if (outcome.missingRequiredData()) {
            return StagingRowSkipReasonFormatter.formatMissingRequiredFields(
                    outcome.missingRequiredColumns(),
                    columnExcelHeaders
            );
        }
        return null;
    }

    private void appendSummaryIssue(AuditExecutionContext context, Sheet sheet, int excelRowOneBased, String reason) {
        context.append(
                AuditLogLevel.WARNING,
                AuditLogScope.FILE,
                "STAGING_ROW_ISSUE",
                "<P>⚠ Excel-строка " + excelRowOneBased + ": " + escape(reason) + ".</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "rowIndex", String.valueOf(excelRowOneBased),
                                "reason", reason
                        ),
                        "WARN",
                        "ORANGE",
                        "NORMAL"
                )
        );
    }

    /**
     * Сбрасывает накопленный диапазон пустых строк одним INFO-сообщением SUMMARY.
     */
    private void flushEmptyRowSkipBatch(AuditExecutionContext context, Sheet sheet, EmptyRowSkipBatch batch) {
        if (batch == null || batch.isEmpty()) {
            return;
        }
        String reason = StagingRowSkipReasonFormatter.formatEmptyRowsBatch(
                batch.firstRow(),
                batch.lastRow(),
                batch.count()
        );
        context.append(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_EMPTY_ROWS_BATCH",
                "<P>" + escape(reason) + ".</P>",
                withPresentationMeta(
                        Map.of(
                                "auditId", String.valueOf(context.getAuditId()),
                                "sheetName", String.valueOf(sheet.getSheetName()),
                                "firstRow", String.valueOf(batch.firstRow()),
                                "lastRow", String.valueOf(batch.lastRow()),
                                "count", String.valueOf(batch.count())
                        ),
                        "INFO",
                        "SILVER",
                        "NORMAL"
                )
        );
        batch.clear();
    }

    /**
     * Непрерывный диапазон пустых Excel-строк для пакетного лога SUMMARY.
     */
    private static final class EmptyRowSkipBatch {
        private int firstRow;
        private int lastRow;
        private int count;

        private void add(int excelRowOneBased) {
            if (count == 0) {
                firstRow = excelRowOneBased;
            }
            lastRow = excelRowOneBased;
            count++;
        }

        private boolean isEmpty() {
            return count == 0;
        }

        private int firstRow() {
            return firstRow;
        }

        private int lastRow() {
            return lastRow;
        }

        private int count() {
            return count;
        }

        private void clear() {
            firstRow = 0;
            lastRow = 0;
            count = 0;
        }
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
            CellReadResult<LocalDate> dateResult = cellReader.readDateResult(cell);
            if (dateResult.ok() && dateResult.value() != null) {
                return escape(RAIN_DATE_HUMAN.format(dateResult.value()));
            }
            String raw = dateResult.rawText();
            if (raw != null && !raw.isBlank()) {
                return escape(raw.trim());
            }
            return escape("(дата не указана)");
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
     * Вертикальный диапазон в одной колонке: от первой строки под заголовком до нижней границы.
     * <p>
     * Для type=5 ({@code allowedSigns != null}) нижняя граница — последняя <em>значимая</em> строка
     * (whitelist / «ОА Аренда» / № ОА с {@code type5RaNumPattern}), а не последняя непустая в якоре.
     * Для прочих типов — по-прежнему последняя непустая ячейка в колонке диапазона.
     * </p>
     */
    private SheetDataRangeSpec buildSheetDataRangeSpec(
            Sheet sheet,
            int headerRowIndex,
            int rangeColumnIndex0,
            Map<String, Integer> excelColumns,
            Set<String> allowedSigns,
            java.util.regex.Pattern type5RaNumPattern
    ) {
        int firstDataRowIndex = headerRowIndex + 1;
        int firstRowOneBased = firstDataRowIndex + 1;
        String colLetters = CellReference.convertNumToColString(rangeColumnIndex0);
        int lastPoi = sheet.getLastRowNum();
        if (lastPoi < firstDataRowIndex) {
            String address = "$" + colLetters + "$" + firstRowOneBased + ":$" + colLetters + "$" + firstRowOneBased;
            return new SheetDataRangeSpec(rangeColumnIndex0 + 1, firstRowOneBased, firstRowOneBased, address);
        }
        int lastDataRowIndex0;
        if (allowedSigns != null && type5RaNumPattern != null) {
            lastDataRowIndex0 = findLastSignificantType5RowIndex0(
                    sheet, firstDataRowIndex, lastPoi, excelColumns, allowedSigns, type5RaNumPattern);
        } else {
            lastDataRowIndex0 = findLastNonEmptyInColumnIndex0(sheet, firstDataRowIndex, lastPoi, rangeColumnIndex0);
        }
        int lastRowOneBased = lastDataRowIndex0 >= 0 ? lastDataRowIndex0 + 1 : firstRowOneBased;
        String address = "$" + colLetters + "$" + firstRowOneBased + ":$" + colLetters + "$" + lastRowOneBased;
        return new SheetDataRangeSpec(rangeColumnIndex0 + 1, firstRowOneBased, lastRowOneBased, address);
    }

    /**
     * Индекс последней значимой строки type=5 (0-based) или {@code -1}, если таких нет.
     */
    private int findLastSignificantType5RowIndex0(
            Sheet sheet,
            int firstDataRowIndex,
            int lastPoi,
            Map<String, Integer> excelColumns,
            Set<String> allowedSigns,
            java.util.regex.Pattern type5RaNumPattern
    ) {
        Integer signCol = excelColumns.get("rainSign");
        Integer raNumCol = excelColumns.get("rainRaNum");
        if (signCol == null && raNumCol == null) {
            return findLastNonEmptyInColumnIndex0(sheet, firstDataRowIndex, lastPoi,
                    excelColumns.values().stream().min(Integer::compareTo).orElse(0));
        }
        for (int r = lastPoi; r >= firstDataRowIndex; r--) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            String signRaw = signCol != null ? cellReader.readString(row.getCell(signCol)) : null;
            String raNumRaw = raNumCol != null ? cellReader.readString(row.getCell(raNumCol)) : null;
            if (Type5SignFilterClassifier.isSignificantForDataRange(
                    signRaw, raNumRaw, allowedSigns, type5RaNumPattern)) {
                return r;
            }
        }
        return -1;
    }

    /**
     * Индекс последней непустой ячейки в колонке (0-based) или {@code -1}.
     */
    private int findLastNonEmptyInColumnIndex0(
            Sheet sheet,
            int firstDataRowIndex,
            int lastPoi,
            int rangeColumnIndex0
    ) {
        for (int r = lastPoi; r >= firstDataRowIndex; r--) {
            Row row = sheet.getRow(r);
            if (row == null) {
                continue;
            }
            if (cellReader.readString(row.getCell(rangeColumnIndex0)) != null) {
                return r;
            }
        }
        return -1;
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

    private Set<String> resolveAllowedSigns(RaSheetConf config, boolean isType5) {
        if (!isType5) {
            return null;
        }
        if (config == null || config.rscSignWhitelist() == null || config.rscSignWhitelist().isBlank()) {
            return TYPE5_ALLOWED_SIGNS;
        }
        Set<String> configured = java.util.Arrays.stream(config.rscSignWhitelist().split("[,;\\n]+"))
                .map(Type5SignFilterClassifier::normalizeSign)
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
        meta.put("filteredArendaBySign", String.valueOf(stats.filteredArendaBySign));
        meta.put("filteredOtherWithoutMarker", String.valueOf(stats.filteredOtherWithoutMarker));
        meta.put("skippedEmptyBeforeSign", String.valueOf(stats.skippedEmptyBeforeSign));
        meta.put("filteredSignsTop", filteredSignsTop);
        meta.put("insertedRows", String.valueOf(stats.insertedRows));
        meta.put("rowParagraphSampled", String.valueOf(stats.rowParagraphSampled));
        meta.put("rowParagraphSuppressed", String.valueOf(stats.rowParagraphSuppressed));
        meta.put("rowParagraphTotal", String.valueOf(stats.rowParagraphTotal));
        meta.put("parseErrorFields", String.valueOf(stats.parseErrorFields));
        meta.put("skippedParseError", String.valueOf(stats.skippedParseError));
        return meta;
    }

    private Map<String, String> buildColumnExcelHeaders(List<RaColMap> mappings, Map<String, Integer> excelColumns) {
        Map<String, String> headers = new HashMap<>();
        for (RaColMap mapping : mappings) {
            String column = mapping.rcmTblCol();
            if (column == null || mapping.rcmXlHdr() == null || !excelColumns.containsKey(column)) {
                continue;
            }
            headers.putIfAbsent(column, mapping.rcmXlHdr());
        }
        return headers;
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

    /**
     * Собирает список колонок INSERT: {@code *_exec_key}, колонка Excel-строки (если есть),
     * затем поля из {@code ra_col_map}, найденные на листе.
     */
    private List<String> resolveInsertColumns(
            List<RaColMap> mappings,
            Map<String, Integer> excelColumns,
            Set<String> dbColumns,
            String execColumn,
            Long executionKey,
            String excelRowColumn
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
        if (excelRowColumn != null && dbColumns.contains(excelRowColumn)) {
            columns.add(excelRowColumn);
        }
        for (RaColMap mapping : sorted) {
            String stagingCol = mapping.rcmTblCol();
            if (excelColumns.containsKey(stagingCol) && dbColumns.contains(stagingCol)) {
                // Не перезаписывать синтетический номер строки значением из Excel-заголовка.
                if (StagingExcelRowColumns.isSynthetic(stagingCol, excelRowColumn)) {
                    continue;
                }
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

    /**
     * Биндит одну Excel-строку в {@link PreparedStatement}.
     *
     * @param excelRowColumn   синтетическая колонка номера строки или {@code null}
     * @param excelRowOneBased номер строки на листе (1-based)
     */
    private RowBindOutcome bindRow(
            PreparedStatement statement,
            Row row,
            List<String> insertColumns,
            Map<String, Integer> excelColumns,
            Map<String, String> columnExcelHeaders,
            Map<String, Integer> dbColumnTypes,
            Map<String, Integer> dbColumnSizes,
            String execColumn,
            Long executionKey,
            String excelRowColumn,
            int excelRowOneBased,
            Set<String> requiredColumns
    ) throws SQLException {
        boolean hasBusinessData = false;
        boolean missingRequiredData = false;
        boolean skippedDueToRequiredParseError = false;
        int optionalParseErrorFields = 0;
        int truncatedFields = 0;
        String rainSign = "(null)";
        List<CellParseIssue> parseIssues = new ArrayList<>();
        List<String> missingRequiredColumns = new ArrayList<>();
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
            if (StagingExcelRowColumns.isSynthetic(column, excelRowColumn)) {
                if (excelRowOneBased > 0) {
                    statement.setInt(parameterIndex, excelRowOneBased);
                } else {
                    statement.setNull(parameterIndex, Types.INTEGER);
                }
                continue;
            }
            Integer excelColIndex = excelColumns.get(column);
            TypedRead typedRead = excelColIndex != null
                    ? readTypedResult(row.getCell(excelColIndex), jdbcType, column, columnExcelHeaders, requiredColumns)
                    : new TypedRead(null, null);
            Object value = typedRead.value();
            if (typedRead.parseIssue() != null) {
                parseIssues.add(typedRead.parseIssue());
                if (typedRead.parseIssue().required()) {
                    skippedDueToRequiredParseError = true;
                } else {
                    optionalParseErrorFields++;
                }
                value = null;
            }
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
                missingRequiredColumns.add(column);
            }
            if (value != null) {
                hasBusinessData = true;
            }
            bindValue(statement, parameterIndex, jdbcType, value);
        }
        boolean insertable = hasBusinessData && !missingRequiredData && !skippedDueToRequiredParseError;
        return new RowBindOutcome(
                insertable,
                missingRequiredData,
                skippedDueToRequiredParseError,
                optionalParseErrorFields,
                parseIssues,
                truncatedFields,
                rainSign,
                hasBusinessData,
                List.copyOf(missingRequiredColumns)
        );
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

    private TypedRead readTypedResult(
            org.apache.poi.ss.usermodel.Cell cell,
            int jdbcType,
            String column,
            Map<String, String> columnExcelHeaders,
            Set<String> requiredColumns
    ) {
        return switch (jdbcType) {
            case Types.DATE -> fromDateResult(cellReader.readDateResult(cell), column, columnExcelHeaders, requiredColumns);
            case Types.INTEGER, Types.SMALLINT, Types.TINYINT, Types.BIGINT ->
                    fromIntResult(cellReader.readIntResult(cell), column, columnExcelHeaders, requiredColumns);
            case Types.DECIMAL, Types.NUMERIC, Types.FLOAT, Types.DOUBLE, Types.REAL ->
                    fromDecimalResult(cellReader.readDecimalResult(cell), column, columnExcelHeaders, requiredColumns);
            case Types.BIT, Types.BOOLEAN -> {
                CellReadResult<Integer> integerResult = cellReader.readIntResult(cell);
                if (!integerResult.ok()) {
                    yield fromIntResult(integerResult, column, columnExcelHeaders, requiredColumns);
                }
                Integer integerValue = integerResult.value();
                yield new TypedRead(integerValue == null ? null : integerValue != 0, null);
            }
            default -> new TypedRead(cellReader.readString(cell), null);
        };
    }

    private TypedRead fromIntResult(
            CellReadResult<Integer> result,
            String column,
            Map<String, String> columnExcelHeaders,
            Set<String> requiredColumns
    ) {
        if (result.ok()) {
            return new TypedRead(result.value(), null);
        }
        return new TypedRead(null, buildParseIssue(column, columnExcelHeaders, requiredColumns, result));
    }

    private TypedRead fromDecimalResult(
            CellReadResult<BigDecimal> result,
            String column,
            Map<String, String> columnExcelHeaders,
            Set<String> requiredColumns
    ) {
        if (result.ok()) {
            return new TypedRead(result.value(), null);
        }
        return new TypedRead(null, buildParseIssue(column, columnExcelHeaders, requiredColumns, result));
    }

    private TypedRead fromDateResult(
            CellReadResult<LocalDate> result,
            String column,
            Map<String, String> columnExcelHeaders,
            Set<String> requiredColumns
    ) {
        if (result.ok()) {
            return new TypedRead(result.value(), null);
        }
        return new TypedRead(null, buildParseIssue(column, columnExcelHeaders, requiredColumns, result));
    }

    private CellParseIssue buildParseIssue(
            String column,
            Map<String, String> columnExcelHeaders,
            Set<String> requiredColumns,
            CellReadResult<?> result
    ) {
        String header = columnExcelHeaders.getOrDefault(column, column);
        String raw = result.rawText() != null ? result.rawText() : "";
        String expected = result.expectedType() != null ? result.expectedType() : "значение";
        return new CellParseIssue(column, header, raw, expected, requiredColumns.contains(column));
    }

    private record TypedRead(Object value, CellParseIssue parseIssue) {
    }

    /**
     * Ошибка формата ячейки при привязке строки staging.
     */
    private record CellParseIssue(String column, String excelHeader, String rawValue, String expectedType, boolean required) {
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

    private record RowBindOutcome(
            boolean insertable,
            boolean missingRequiredData,
            boolean skippedDueToRequiredParseError,
            int optionalParseErrorFields,
            List<CellParseIssue> parseIssues,
            int truncatedFields,
            String rainSign,
            boolean hasBusinessData,
            List<String> missingRequiredColumns
    ) {
    }

    private static final class SheetLoadStats {
        private final String sheetName;
        private final String stagingTable;
        private final int firstDataRow;
        private final int lastDataRow;
        private long sourceRows;
        private long acceptedBySign;
        private long filteredBySign;
        /** Отсев по признаку «ОА Аренда» (входит в {@link #filteredBySign}). */
        private long filteredArendaBySign;
        /**
         * Прочие строки без маркера № ОА ({@code \d{7}} и т.п.) — внутри диапазона и в хвосте.
         */
        private long filteredOtherWithoutMarker;
        /** Сколько OTHER уже выведено поштучным WARN (лимит топа). */
        private long filteredOtherDetailsLogged;
        private long acceptedRows;
        private long insertedRows;
        private long skippedNullRow;
        /**
         * Пустые строки (нет признака и № ОА), отсечённые до фильтра whitelist —
         * не входят в {@link #filteredBySign} / UNKNOWN_SIGN.
         */
        private long skippedEmptyBeforeSign;
        private long skippedNoBusinessData;
        private long skippedMissingRequired;
        private long parseErrorFields;
        private long skippedParseError;
        private long rowsWithTruncation;
        private long totalTruncatedFields;
        private final Map<String, Integer> acceptedSignCounts = new java.util.TreeMap<>();
        private final Map<String, Integer> filteredSignCounts = new java.util.TreeMap<>();
        private long rowParagraphSampled;
        private long rowParagraphSuppressed;
        private long rowParagraphTotal;
        /** Строк листа ниже нижней границы найденного диапазона (не обрабатывались). */
        private long skippedBeyondRange;

        private SheetLoadStats(String sheetName, String stagingTable, int firstDataRow, int lastDataRow) {
            this.sheetName = sheetName;
            this.stagingTable = stagingTable;
            this.firstDataRow = firstDataRow;
            this.lastDataRow = lastDataRow;
        }
    }
}
