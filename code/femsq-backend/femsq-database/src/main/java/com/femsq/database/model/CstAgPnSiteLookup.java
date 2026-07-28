package com.femsq.database.model;

import java.util.Objects;

/**
 * Lookup САК стройки для combo «стройка» ({@code ra_cac}).
 *
 * @param cstapKey    ключ САК
 * @param cstapIpgPnN код САК
 * @param cstaKey     ключ агента на стройке
 * @param agentLabel  подпись агента
 */
public record CstAgPnSiteLookup(
        Integer cstapKey,
        String cstapIpgPnN,
        Integer cstaKey,
        String agentLabel
) {

    public CstAgPnSiteLookup {
        Objects.requireNonNull(cstapKey, "cstapKey");
        Objects.requireNonNull(cstapIpgPnN, "cstapIpgPnN");
        Objects.requireNonNull(cstaKey, "cstaKey");
    }
}
