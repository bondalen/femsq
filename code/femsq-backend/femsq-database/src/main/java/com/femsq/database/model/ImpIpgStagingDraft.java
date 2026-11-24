package com.femsq.database.model;

/**
 * Черновик строки staging перед записью в {@code ags.impIpg}.
 * {@code parentIndex} — индекс родителя в том же списке (null = корень).
 */
public record ImpIpgStagingDraft(
        int rowNo,
        String rowKind,
        String text,
        Integer parentIndex,
        String ctx) {
}
