package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет цепочку инвестиционных программ (таблица {@code ags.ipgCh}) для DAO-слоя.
 *
 * @param chainKey     идентификатор цепочки ({@code ipgcKey})
 * @param name         наименование цепочки ({@code ipgcName})
 * @param stNetKey     идентификатор структуры сети ({@code ipgcStNetIpg})
 * @param latestIpgKey идентификатор "поздней" инвестиционной программы ({@code ipgcIpgLate})
 * @param year         отчётный год цепочки ({@code ipgcYyyy})
 */
public record IpgChain(
        Integer chainKey,
        String name,
        Integer stNetKey,
        Integer latestIpgKey,
        Integer year
) {

    public IpgChain {
        Objects.requireNonNull(chainKey, "chainKey");
        Objects.requireNonNull(name, "name");
    }
}
