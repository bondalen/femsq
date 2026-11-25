package com.femsq.database.model;

import java.util.List;
import java.util.Objects;

/**
 * Превью резолва {@code ipgpSh} без записи в домен (§3.2.3).
 */
public record ImpIpgShResolveResult(
        int loadKey,
        int ipgKey,
        Integer previousIpgKey,
        int leafCount,
        int resolvedCount,
        int errorCount,
        int fromPrevCount,
        int default4Count,
        int freePoolCount,
        boolean ready,
        List<String> errors,
        List<ImpIpgShResolveLeaf> problemLeaves,
        List<ImpIpgShResolveLeaf> resolvedLeaves
) {
    public ImpIpgShResolveResult {
        Objects.requireNonNull(errors, "errors");
        Objects.requireNonNull(problemLeaves, "problemLeaves");
        Objects.requireNonNull(resolvedLeaves, "resolvedLeaves");
        errors = List.copyOf(errors);
        problemLeaves = List.copyOf(problemLeaves);
        resolvedLeaves = List.copyOf(resolvedLeaves);
    }
}
