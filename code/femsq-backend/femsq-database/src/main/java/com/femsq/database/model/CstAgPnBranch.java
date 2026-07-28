package com.femsq.database.model;

import java.time.LocalDate;
import java.util.Objects;

/**
 * Филиал САК (таблица {@code ags.cstAgPnBranch}).
 *
 * @param cstapbKey      идентификатор (PRIMARY KEY, identity)
 * @param cstapbCstAgPn  ключ {@code cstAgPn}
 * @param cstapbBranch   ключ организации-филиала ({@code ags.og.ogKey})
 * @param cstapbStart    дата начала
 * @param cstapbEnd      дата окончания
 * @param branchName     наименование филиала из {@code ags.og.ogNm} (только чтение)
 */
public record CstAgPnBranch(
        Integer cstapbKey,
        Integer cstapbCstAgPn,
        Integer cstapbBranch,
        LocalDate cstapbStart,
        LocalDate cstapbEnd,
        String branchName
) {

    public CstAgPnBranch {
        Objects.requireNonNull(cstapbCstAgPn, "cstapbCstAgPn");
        Objects.requireNonNull(cstapbBranch, "cstapbBranch");
    }
}
