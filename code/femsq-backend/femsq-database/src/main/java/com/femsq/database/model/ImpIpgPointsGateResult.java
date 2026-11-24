package com.femsq.database.model;

import java.util.List;
import java.util.Objects;

/**
 * Результат gate загрузки пунктов (§3.2.1): ПТСФ закрыт и у ipg задан {@code ipgStRlSh}.
 */
public record ImpIpgPointsGateResult(
        int loadKey,
        int ipgKey,
        Integer stNetKey,
        int sectionCount,
        int openCount,
        boolean ready,
        List<String> errors,
        List<Integer> openRowIds
) {
    public ImpIpgPointsGateResult {
        Objects.requireNonNull(errors, "errors");
        Objects.requireNonNull(openRowIds, "openRowIds");
        errors = List.copyOf(errors);
        openRowIds = List.copyOf(openRowIds);
    }
}
