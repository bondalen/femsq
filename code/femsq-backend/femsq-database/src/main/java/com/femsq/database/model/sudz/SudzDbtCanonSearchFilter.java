package com.femsq.database.model.sudz;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Фильтр поиска канонов Dbt (S78): все поля опциональны, нужен хотя бы один критерий.
 *
 * @param cnNum номер договора ({@code cnnNumNull}), like
 * @param invNum номер СФ ({@code inNumNull}), like
 * @param orgBuirg БУиРГ исполнителя ({@code org_id_type=1})
 * @param orgName краткое имя ({@code og.ogNm}), like
 * @param csoDate дата стороны; null в БД сравнивается с 1900-01-01
 * @param idNum номер слота в СФ ({@code invDbt.idNum})
 * @param dbtKey ключ канона
 * @param limit макс. число кандидатов (1..200)
 */
public record SudzDbtCanonSearchFilter(
        String cnNum,
        String invNum,
        Integer orgBuirg,
        String orgName,
        LocalDate csoDate,
        Integer idNum,
        Integer dbtKey,
        int limit
) {
}
