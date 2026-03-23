package com.femsq.web.audit.staging;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.RaColMap;
import com.femsq.database.model.RaSheetConf;
import com.femsq.web.audit.AuditExecutionContext;
import com.femsq.web.audit.AuditFile;
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
import java.time.LocalDate;
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

        return excelReader.withWorkbook(file.getPath(), workbook -> loadWorkbook(context, workbook, sheetConfigs));
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
            throw new AuditExcelException("Failed to load staging data", exception);
        }
        return totalInserted;
    }

    private int loadSheet(AuditExecutionContext context, Connection connection, Workbook workbook, RaSheetConf config)
            throws SQLException {
        Sheet sheet = resolveSheet(workbook, config.rscSheet());
        if (sheet == null) {
            throw new AuditExcelException("Sheet not found: " + config.rscSheet());
        }

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

        Map<String, Integer> dbColumnTypes = readColumnTypes(connection, config.rscStgTbl());
        String execColumn = findExecColumn(dbColumnTypes.keySet());

        List<String> insertColumns = resolveInsertColumns(mappings, excelColumns, dbColumnTypes.keySet(), execColumn, context.getExecutionKey());
        if (insertColumns.isEmpty()) {
            return 0;
        }

        String insertSql = buildInsertSql(config.rscStgTbl(), insertColumns);
        int inserted = 0;
        int batchCount = 0;
        try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
            for (int rowIndex = headerRowIndex + 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    continue;
                }
                if (!bindRow(statement, row, insertColumns, excelColumns, dbColumnTypes, execColumn, context.getExecutionKey())) {
                    continue;
                }
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
        return inserted;
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
        String sql = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?";
        Map<String, Integer> result = new HashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, parts[0]);
            statement.setString(2, parts[1]);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    String name = rs.getString("COLUMN_NAME");
                    int jdbcType = rs.getInt("DATA_TYPE");
                    result.put(name, jdbcType);
                }
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

    private boolean bindRow(
            PreparedStatement statement,
            Row row,
            List<String> insertColumns,
            Map<String, Integer> excelColumns,
            Map<String, Integer> dbColumnTypes,
            String execColumn,
            Long executionKey
    ) throws SQLException {
        boolean hasBusinessData = false;
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
            if (value != null) {
                hasBusinessData = true;
            }
            bindValue(statement, parameterIndex, jdbcType, value);
        }
        return hasBusinessData;
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
}
