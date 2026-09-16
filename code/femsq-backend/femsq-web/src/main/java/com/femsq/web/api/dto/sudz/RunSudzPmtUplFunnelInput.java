package com.femsq.web.api.dto.sudz;

import java.util.List;

/**
 * GraphQL input прогона воронки платежей (0074).
 *
 * @param pmKey ключ пакета
 * @param steps префикс cipu* (без excelToTbl)
 * @param flLoad флаг «Обновлять» (в логе; apply — позже)
 */
public record RunSudzPmtUplFunnelInput(
        int pmKey,
        List<String> steps,
        boolean flLoad
) {
}
