package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * Вход поиска канонов Dbt (S78).
 *
 * @param cnNum номер договора
 * @param invNum номер СФ
 * @param orgBuirg БУиРГ
 * @param orgName краткое имя организации
 * @param csoDate дата стороны
 * @param idNum номер слота в СФ
 * @param dbtKey ключ канона
 * @param limit лимит кандидатов
 */
public record SudzDbtCanonSearchInput(
        String cnNum,
        String invNum,
        Integer orgBuirg,
        String orgName,
        LocalDate csoDate,
        Integer idNum,
        Integer dbtKey,
        Integer limit
) {
}
