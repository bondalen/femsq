package com.femsq.database.model;

/**
 * Лист staging с результатом резолва {@code ipgpSh} (§3.2.3).
 *
 * <p>{@code resolvedSh == null} — ошибка; {@code errorReason} тогда непустой.
 */
public record ImpIpgShResolveLeaf(
        int rowId,
        int rowNo,
        String text,
        String cstAgPnCode,
        Integer resolvedSh,
        ImpIpgShResolveSource source,
        String errorReason
) {
    /**
     * @return {@code true}, если схема назначена без ошибки
     */
    public boolean ok() {
        return resolvedSh != null && errorReason == null;
    }
}
