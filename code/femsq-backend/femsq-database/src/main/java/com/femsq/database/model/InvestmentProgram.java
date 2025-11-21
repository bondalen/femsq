package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет инвестиционную программу с отформатированным названием для lookup.
 * Название формируется из {@code ags.ipg}, {@code ags.og}, {@code ags.yyyy}.
 */
public record InvestmentProgram(
        Integer ipgKey,
        String displayName
) {
    public InvestmentProgram {
        Objects.requireNonNull(ipgKey, "ipgKey");
        Objects.requireNonNull(displayName, "displayName");
    }
}
