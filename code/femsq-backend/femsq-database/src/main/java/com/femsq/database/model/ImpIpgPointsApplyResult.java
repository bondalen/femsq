package com.femsq.database.model;

import java.util.List;
import java.util.Objects;

/**
 * Итог apply пунктов из staging (§3.2.4 / §3.2.7 partial).
 *
 * <p>{@code ready=true} — в логе нет ошибок строк (skipped «уже есть» не ошибка).
 * Частичный успех: {@code appliedCount>0} при {@code !ready} допустим.
 * {@code logHtml} — накопительный лог «Ход загрузки» (C2 §3.5.4), nullable.
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
        List<Integer> createdPnKeys,
        String logHtml
) {
    public ImpIpgPointsApplyResult {
        Objects.requireNonNull(errors, "errors");
        Objects.requireNonNull(problemRowIds, "problemRowIds");
        Objects.requireNonNull(createdPnKeys, "createdPnKeys");
        errors = List.copyOf(errors);
        problemRowIds = List.copyOf(problemRowIds);
        createdPnKeys = List.copyOf(createdPnKeys);
    }

    /** Конструктор без лога ({@code logHtml = null}). */
    public ImpIpgPointsApplyResult(
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
            List<Integer> createdPnKeys) {
        this(loadKey, ipgKey, previousIpgKey, dryRun, leafCount, appliedCount, skippedAlreadyCount,
                ready, errors, problemRowIds, createdPnKeys, null);
    }

    /** Копия с накопительным HTML-логом. */
    public ImpIpgPointsApplyResult withLogHtml(String html) {
        return new ImpIpgPointsApplyResult(loadKey, ipgKey, previousIpgKey, dryRun, leafCount,
                appliedCount, skippedAlreadyCount, ready, errors, problemRowIds, createdPnKeys, html);
    }
}
