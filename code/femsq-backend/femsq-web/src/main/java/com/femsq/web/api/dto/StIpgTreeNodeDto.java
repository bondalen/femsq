package com.femsq.web.api.dto;

/**
 * DTO строки дерева структуры ИПГ.
 */
public record StIpgTreeNodeDto(
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
