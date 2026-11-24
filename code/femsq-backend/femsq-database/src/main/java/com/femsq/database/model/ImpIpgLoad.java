package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Сессия загрузки Excel годовой ИП ({@code ags.impIpgLoad}).
 */
public final class ImpIpgLoad {

    private final int iilKey;
    private final int iilIpg;
    private final String iilNm;
    private final String iilFilePath;
    private final String iilNote;
    private final LocalDateTime iilCreated;

    public ImpIpgLoad(
            int iilKey,
            int iilIpg,
            String iilNm,
            String iilFilePath,
            String iilNote,
            LocalDateTime iilCreated) {
        this.iilKey = iilKey;
        this.iilIpg = iilIpg;
        this.iilNm = Objects.requireNonNull(iilNm, "iilNm");
        this.iilFilePath = iilFilePath;
        this.iilNote = iilNote;
        this.iilCreated = iilCreated;
    }

    public int iilKey() {
        return iilKey;
    }

    public int iilIpg() {
        return iilIpg;
    }

    public String iilNm() {
        return iilNm;
    }

    public String iilFilePath() {
        return iilFilePath;
    }

    public String iilNote() {
        return iilNote;
    }

    public LocalDateTime iilCreated() {
        return iilCreated;
    }
}
