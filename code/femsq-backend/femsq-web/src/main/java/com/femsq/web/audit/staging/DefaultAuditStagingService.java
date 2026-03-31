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
import java.sql.Types;
import java.time.Instant;
import java.time.LocalDate;
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
import java.util.logging.Logger;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.springframework.stereotype.Service;

/**
 * Реализация Stage 1 (Excel -> staging) на основе декларативного маппинга.
 */
@Service
public class DefaultAuditStagingService implements AuditStagingService {

    private static final Logger log = Logger.getLogger(DefaultAuditStagingService.class.getName());
    private static final int BATCH_SIZE = 200;

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

        Instant openedAt = Instant.now();
        String workbookSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "WORKBOOK_OPEN",
                "<P>Книга открывается: " + escape(file.getPath()) + "</P>",
                null
        );
        try {
            return context.inSpan(workbookSpanId, () -> excelReader.withWorkbook(file.getPath(), workbook -> loadWorkbook(context, workbook, sheetConfigs)));
        } finally {
            Instant closedAt = Instant.now();
            context.endSpan(workbookSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "WORKBOOK_CLOSE",
                    "<P>Книга закрыта: " + escape(file.getPath()) + ". Duration: " + formatDuration(openedAt, closedAt) + "</P>",
                    null);
        }
    }

    private int loadWorkbook(AuditExecutionContext context, Workbook workbook, List<RaSheetConf> sheetConfigs) {
        int totalInserted = 0;
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(false);
            try {
                for (RaSheetConf config : sheetConfigs) {
                    totalInserted += loadSheet(context, connection, workbook, config);
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

    private int loadSheet(AuditExecutionContext context, Connection connection, Workbook workbook, RaSheetConf config)
            throws SQLException {
        Instant stagingStartedAt = Instant.now();
        String stagingSpanId = context.beginSpan(
                AuditLogLevel.INFO,
                AuditLogScope.FILE,
                "STAGING_START",
                "<P>Staging start: table=" + escape(config.rscStgTbl()) + ", sheet=" + escape(config.rscSheet()) + "</P>",
                null
        );
        Sheet sheet = resolveSheet(workbook, config.rscSheet());
        if (sheet == null) {
            context.append(AuditLogLevel.WARNING, AuditLogScope.FILE, "SHEET_MISSING",
                    "<P>Лист не найден: " + escape(config.rscSheet()) + "</P>", null);
            throw new AuditExcelException("Sheet not found: " + config.rscSheet());
        }
        context.append(AuditLogLevel.INFO, AuditLogScope.FILE, "SHEET_FOUND",
                "<P>Лист найден: " + escape(sheet.getSheetName()) + "</P>", null);

        OptionalInt anchorRowOpt = columnLocator.findAnchorRow(sheet, config.rscAnchor(), config.rscAnchorMatch());
        if (anchorRowOpt.isEmpty()) {
            throw new AuditExcelException("Anchor not found: " + config.rscAnchor() + ", sheet=" + sheet.getSheetName());
        }

        int headerRowIndex = anchorRowOpt.getAsInt();
        Row headerRow = sheet.getRow(headerRowIndex);
        if (headerRow == null) {
            throw new AuditExcelException("Header row is missing at index " + headerRowIndex + ", sheet=" + sheet.getSheetName());
        }

        List<RaColMap> mappings = mappingRepository.getColumnMappings(config.rscKey());
        Map<String, Integer> excelColumns = columnLocator.locateColumns(headerRow, mappings);
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
        try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
            for (int rowIndex = headerRowIndex + 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                stats.sourceRows++;
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    stats.skippedNullRow++;
                    continue;
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
                    continue;
                }
                if (outcome.truncatedFields() > 0) {
                    stats.rowsWithTruncation++;
                    stats.totalTruncatedFields += outcome.truncatedFields();
                }
                stats.acceptedRows++;
                stats.acceptedSignCounts.compute(outcome.rainSign(), (k, v) -> v == null ? 1 : v + 1);
                statement.addBatch();
                batchCount++;
                if (batchCount >= BATCH_SIZE) {
                    inserted += executeBatch(statement);
                    batchCount = 0;
                }
            }
            if (batchCount > 0) {
                inserted += executeBatch(statement);
            }
        }
        stats.insertedRows = inserted;
        logSheetStats(context, stats);
        Instant stagingEndedAt = Instant.now();
        context.endSpan(stagingSpanId, AuditLogLevel.INFO, AuditLogScope.FILE, "STAGING_END",
                "<P>Staging end: table=" + escape(config.rscStgTbl()) + ", sheet=" + escape(sheet.getSheetName())
                        + ", inserted=" + inserted + ", duration=" + formatDuration(stagingStartedAt, stagingEndedAt) + "</P>",
                null);
        return inserted;
    }

    private void logSheetStats(AuditExecutionContext context, SheetLoadStats stats) {
        String signStats = formatSignStats(stats.acceptedSignCounts);
        String message = "[AuditStaging] sheet=" + stats.sheetName
                + ", table=" + stats.stagingTable
                + ", rowRange=" + stats.firstDataRow + "-" + stats.lastDataRow
                + ", sourceRows=" + stats.sourceRows
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
                Map.of("sheet", stats.sheetName, "table", stats.stagingTable)
        );
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
        private long acceptedRows;
        private long insertedRows;
        private long skippedNullRow;
        private long skippedNoBusinessData;
        private long skippedMissingRequired;
        private long rowsWithTruncation;
        private long totalTruncatedFields;
        private final Map<String, Integer> acceptedSignCounts = new java.util.TreeMap<>();

        private SheetLoadStats(String sheetName, String stagingTable, int firstDataRow, int lastDataRow) {
            this.sheetName = sheetName;
            this.stagingTable = stagingTable;
            this.firstDataRow = firstDataRow;
            this.lastDataRow = lastDataRow;
        }
    }
}
