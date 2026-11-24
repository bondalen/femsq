package com.femsq.database.model;

/**
 * Строка staging разбора Excel ({@code ags.impIpg}).
 *
 * <p>{@code rowKind}: {@code S} — раздел структуры (ПТСФ), {@code L} — лист-стройка.
 */
public final class ImpIpgRow {

    private final int iiKey;
    private final int iiLoad;
    private final int iiRowNo;
    private final String iiRowKind;
    private final String iiText;
    private final Integer iiParent;
    private final Integer iiStiKey;
    private final String iiCtx;

    public ImpIpgRow(
            int iiKey,
            int iiLoad,
            int iiRowNo,
            String iiRowKind,
            String iiText,
            Integer iiParent,
            Integer iiStiKey,
            String iiCtx) {
        this.iiKey = iiKey;
        this.iiLoad = iiLoad;
        this.iiRowNo = iiRowNo;
        this.iiRowKind = iiRowKind;
        this.iiText = iiText;
        this.iiParent = iiParent;
        this.iiStiKey = iiStiKey;
        this.iiCtx = iiCtx;
    }

    public int iiKey() {
        return iiKey;
    }

    public int iiLoad() {
        return iiLoad;
    }

    public int iiRowNo() {
        return iiRowNo;
    }

    public String iiRowKind() {
        return iiRowKind;
    }

    public String iiText() {
        return iiText;
    }

    public Integer iiParent() {
        return iiParent;
    }

    public Integer iiStiKey() {
        return iiStiKey;
    }

    public String iiCtx() {
        return iiCtx;
    }

    public boolean isStructure() {
        return "S".equalsIgnoreCase(iiRowKind);
    }
}
