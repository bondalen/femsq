package com.femsq.database.model;

import java.util.List;
import java.util.Objects;

/**
 * Превью / проверка наследования sti L←S без записи в staging и домен (§3.2.2).
 */
public record ImpIpgStiInheritResult(
        int loadKey,
        int ipgKey,
        int leafCount,
        int readyCount,
        int holeCount,
        boolean ready,
        List<String> errors,
        List<ImpIpgStiInheritLeaf> holes,
        List<ImpIpgStiInheritLeaf> readyLeaves
) {
    public ImpIpgStiInheritResult {
        Objects.requireNonNull(errors, "errors");
        Objects.requireNonNull(holes, "holes");
        Objects.requireNonNull(readyLeaves, "readyLeaves");
        errors = List.copyOf(errors);
        holes = List.copyOf(holes);
        readyLeaves = List.copyOf(readyLeaves);
    }
}
