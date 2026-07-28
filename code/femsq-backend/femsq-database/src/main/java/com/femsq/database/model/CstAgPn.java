package com.femsq.database.model;

import java.util.Objects;
import java.util.UUID;

/**
 * САК / пункт ИП агента на стройке (таблица {@code ags.cstAgPn}).
 *
 * @param cstapKey     идентификатор (PRIMARY KEY, identity)
 * @param cstapCsta    ключ {@code cstAg}
 * @param cstapIpgPnN  код пункта ИП / САК
 * @param cstapOidOld  устаревший OID
 */
public record CstAgPn(
        Integer cstapKey,
        Integer cstapCsta,
        String cstapIpgPnN,
        UUID cstapOidOld
) {

    public CstAgPn {
        Objects.requireNonNull(cstapCsta, "cstapCsta");
        Objects.requireNonNull(cstapIpgPnN, "cstapIpgPnN");
    }
}
