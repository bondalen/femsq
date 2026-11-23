package com.femsq.database.model;

/**
 * Строка обхода {@code ags.fnSt} для UI структуры ИПГ.
 */
public record StIpgTreeNode(
        Integer childKey,
        Integer parentKey,
        Integer stpnNum,
        Integer pnLevel,
        String stNum,
        String name,
        Integer stRelKey,
        Integer stNetPnKey
) {
}
