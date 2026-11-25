package com.femsq.database.model;

import java.util.List;
import java.util.Objects;

/**
 * Итог apply пунктов из staging (§3.2.4 / §3.2.7 partial).
 *
 * <p>{@code ready=true} — в логе нет ошибок строк (skipped «уже есть» не ошибка).
 * Частичный успех: {@code appliedCount>0} при {@code !ready} допустим.
 */
public record ImpIpgPointsApplyResult(
        int loadKey,
        int ipgKey,
        Integer previousIpgKey,
        boolean dryRun,
        int leafCount,
        int appliedCount,
        int skippedAlreadyCount,
        boolean ready,
        List<String> errors,
        List<Integer> problemRowIds,
        List<Integer> createdPnKeys
) {
    public ImpIpgPointsApplyResult {
        Objects.requireNonNull(errors, "errors");
        Objects.requireNonNull(problemRowIds, "problemRowIds");
        Objects.requireNonNull(createdPnKeys, "createdPnKeys");
        errors = List.copyOf(errors);
        problemRowIds = List.copyOf(problemRowIds);
        createdPnKeys = List.copyOf(createdPnKeys);
    }
}
