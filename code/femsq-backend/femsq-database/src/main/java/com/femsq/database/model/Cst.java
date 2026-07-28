package com.femsq.database.model;

import java.util.Objects;
import java.util.UUID;

/**
 * Стройка (таблица {@code ags.cst}).
 *
 * @param cstKey    идентификатор (PRIMARY KEY, identity)
 * @param cstName   наименование стройки
 * @param cstBusSgm бизнес-сегмент (опционально)
 * @param cstOidOld устаревший OID
 * @param cstMark   служебная метка
 */
public record Cst(
        Integer cstKey,
        String cstName,
        String cstBusSgm,
        UUID cstOidOld,
        Integer cstMark
) {

    public Cst {
        Objects.requireNonNull(cstName, "cstName");
    }
}
