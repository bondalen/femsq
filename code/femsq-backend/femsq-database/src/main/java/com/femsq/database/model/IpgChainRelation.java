package com.femsq.database.model;

import java.util.Objects;

/**
 * Представляет связь цепочки инвестиционных программ с конкретной программой (таблица {@code ags.ipgChRl}).
 *
 * @param relationKey           идентификатор записи ({@code ipgcrKey})
 * @param chainKey              идентификатор цепочки ({@code ipgcrChain})
 * @param investmentProgramKey  идентификатор инвестиционной программы ({@code ipgcrIpg})
 * @param planGroupKey          идентификатор группы планов ({@code ipgcrUtPlGr})
 */
public record IpgChainRelation(
        Integer relationKey,
        Integer chainKey,
        Integer investmentProgramKey,
        Integer planGroupKey
) {

    public IpgChainRelation {
        Objects.requireNonNull(relationKey, "relationKey");
        Objects.requireNonNull(chainKey, "chainKey");
        Objects.requireNonNull(investmentProgramKey, "investmentProgramKey");
    }
}
