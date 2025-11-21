package com.femsq.web.api.dto;

/**
 * DTO цепочки инвестиционных программ.
 */
public record IpgChainDto(
        Integer chainKey,
        String name,
        Integer stNetKey,
        String stNetName,
        Integer latestIpgKey,
        Integer year
) {
}
