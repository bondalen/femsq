package com.femsq.web.api.dto;

/**
 * Lookup САК стройки для {@code ra_cac}.
 */
public record CstAgPnSiteLookupDto(
        Integer cstapKey,
        String cstapIpgPnN,
        Integer cstaKey,
        String agentLabel
) {
}
