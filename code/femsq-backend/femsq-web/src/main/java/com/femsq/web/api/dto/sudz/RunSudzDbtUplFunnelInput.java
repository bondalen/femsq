package com.femsq.web.api.dto.sudz;

import java.util.List;

/**
 * GraphQL input прогона воронки (S61f).
 *
 * @param uplKey ключ выгрузки
 * @param steps префикс цепочки stepId
 * @param flLoad писать ли в БД (для stub — только отражается в логе)
 */
public record RunSudzDbtUplFunnelInput(
        int uplKey,
        List<String> steps,
        boolean flLoad
) {
}
