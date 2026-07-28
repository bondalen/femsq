package com.femsq.database.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Агент на стройке (таблица {@code ags.cstAg}).
 *
 * @param cstaKey      идентификатор (PRIMARY KEY, identity)
 * @param cstaAg       ключ агента ({@code ags.ogAg.ogaKey})
 * @param cstaCst      ключ стройки ({@code ags.cst.cstKey})
 * @param cstaOidOld   устаревший OID
 * @param cstaInvestor признак инвестора (в Access default 7)
 * @param agentLabel   подпись агента из {@code ags.ogAgCs.ogaNm} (только чтение)
 */
public record CstAg(
        Integer cstaKey,
        Integer cstaAg,
        Integer cstaCst,
        UUID cstaOidOld,
        Integer cstaInvestor,
        String agentLabel
) {

    public CstAg {
        Objects.requireNonNull(cstaAg, "cstaAg");
        Objects.requireNonNull(cstaCst, "cstaCst");
    }
}
