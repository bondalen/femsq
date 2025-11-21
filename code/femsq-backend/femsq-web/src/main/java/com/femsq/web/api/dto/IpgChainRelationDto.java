package com.femsq.web.api.dto;

/**
 * DTO связи цепочки инвестиционных программ с конкретной программой.
 */
public record IpgChainRelationDto(
        Integer relationKey,
        Integer chainKey,
        Integer investmentProgramKey,
        String investmentProgramName,
        Integer planGroupKey,
        String planGroupName
) {
}
