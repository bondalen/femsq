package com.femsq.database.model;

/**
 * Лист staging с результатом наследования {@code stiKey} от родителя-раздела (§3.2.2).
 *
 * <p>{@code resolvedStiKey == null} означает дыру; {@code holeReason} тогда непустой.
 */
public record ImpIpgStiInheritLeaf(
        int rowId,
        int rowNo,
        String text,
        Integer parentKey,
        Integer resolvedStiKey,
        String holeReason
) {
    /**
     * @return {@code true}, если sti родителя резолвлен
     */
    public boolean ready() {
        return resolvedStiKey != null;
    }
}
