package com.femsq.database.dao;

import com.femsq.database.model.sudz.SudzPmtUplTblRow;
import com.microsoft.sqlserver.jdbc.ISQLServerBulkData;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * Источник строк для {@code SQLServerBulkCopy} → {@code CnInvPmtUplTbl} (без identity ciputKey).
 */
final class SudzPmtUplTblBulkData implements ISQLServerBulkData {

    private static final String[] NAMES = {
            "ciputBE", "ciputAccount", "ciputCntrPrtNum", "ciputCntrPrtName", "ciputCAC",
            "ciputAgentNum", "ciputAgentName", "ciputCnName", "ciputLink", "ciputCnInv",
            "ciputEntryDate", "ciputDocDate", "ciputDueDate",
            "ciputDbtBlns", "ciputDbtBlnsOverd", "ciputDbtBlnsOverdNot",
            "ciputCdtBlns", "ciputCdtBlnsOverd", "ciputCdtBlnsOverdNot", "ciputBlns",
            "ciputCnInvDocCode", "ciputAlligmentDate", "ciputBaseDate", "ciputCnInvDocSum",
            "ciputStornoReason", "ciputStornoDocCode", "ciputSheetNum", "ciputUnloadKey"
    };

    /**
     * Имена колонок назначения (без identity) — для {@code addColumnMapping}.
     *
     * @return копия имён
     */
    static String[] columnNames() {
        return NAMES.clone();
    }

    private static final int[] SQL_TYPES = {
            Types.NVARCHAR, Types.INTEGER, Types.INTEGER, Types.NVARCHAR, Types.NVARCHAR,
            Types.INTEGER, Types.NVARCHAR, Types.NVARCHAR, Types.NVARCHAR, Types.NVARCHAR,
            Types.TIMESTAMP, Types.TIMESTAMP, Types.TIMESTAMP,
            Types.DECIMAL, Types.DECIMAL, Types.DECIMAL,
            Types.DECIMAL, Types.DECIMAL, Types.DECIMAL, Types.DECIMAL,
            Types.NVARCHAR, Types.TIMESTAMP, Types.TIMESTAMP, Types.DECIMAL,
            Types.NVARCHAR, Types.NVARCHAR, Types.INTEGER, Types.INTEGER
    };

    /** Длина nvarchar в символах (sys.columns.max_length/2). */
    private static final int[] PRECISIONS = {
            50, 0, 0, 255, 50,
            0, 255, 255, 255, 255,
            0, 0, 0,
            19, 19, 19,
            19, 19, 19, 19,
            50, 0, 0, 19,
            255, 50, 0, 0
    };

    private static final int[] SCALES = {
            0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 0,
            4, 4, 4,
            4, 4, 4, 4,
            0, 0, 0, 4,
            0, 0, 0, 0
    };

    private final List<SudzPmtUplTblRow> rows;
    private final Set<Integer> ordinals;
    private int index = -1;

    SudzPmtUplTblBulkData(List<SudzPmtUplTblRow> rows) {
        this.rows = Objects.requireNonNull(rows, "rows");
        Set<Integer> set = new LinkedHashSet<>();
        for (int i = 1; i <= NAMES.length; i++) {
            set.add(i);
        }
        this.ordinals = Set.copyOf(set);
    }

    @Override
    public Set<Integer> getColumnOrdinals() {
        return ordinals;
    }

    @Override
    public String getColumnName(int column) {
        return NAMES[column - 1];
    }

    @Override
    public int getColumnType(int column) {
        return SQL_TYPES[column - 1];
    }

    @Override
    public int getPrecision(int column) {
        return PRECISIONS[column - 1];
    }

    @Override
    public int getScale(int column) {
        return SCALES[column - 1];
    }

    @Override
    public Object[] getRowData() {
        SudzPmtUplTblRow row = rows.get(index);
        return new Object[]{
                row.ciputBE(),
                row.ciputAccount(),
                row.ciputCntrPrtNum(),
                row.ciputCntrPrtName(),
                row.ciputCAC(),
                row.ciputAgentNum(),
                row.ciputAgentName(),
                row.ciputCnName(),
                row.ciputLink(),
                row.ciputCnInv(),
                toTimestamp(row.ciputEntryDate()),
                toTimestamp(row.ciputDocDate()),
                toTimestamp(row.ciputDueDate()),
                decimal(row.ciputDbtBlns()),
                decimal(row.ciputDbtBlnsOverd()),
                decimal(row.ciputDbtBlnsOverdNot()),
                decimal(row.ciputCdtBlns()),
                decimal(row.ciputCdtBlnsOverd()),
                decimal(row.ciputCdtBlnsOverdNot()),
                decimal(row.ciputBlns()),
                row.ciputCnInvDocCode(),
                toTimestamp(row.ciputAlligmentDate()),
                toTimestamp(row.ciputBaseDate()),
                decimal(row.ciputCnInvDocSum()),
                row.ciputStornoReason(),
                row.ciputStornoDocCode(),
                row.ciputSheetNum(),
                row.ciputUnloadKey()
        };
    }

    @Override
    public boolean next() {
        index++;
        return index < rows.size();
    }

    private static Timestamp toTimestamp(LocalDateTime value) {
        return value == null ? null : Timestamp.valueOf(value);
    }

    private static BigDecimal decimal(BigDecimal value) {
        return value;
    }
}
