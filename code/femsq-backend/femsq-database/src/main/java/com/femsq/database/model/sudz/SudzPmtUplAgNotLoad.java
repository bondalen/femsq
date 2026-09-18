package com.femsq.database.model.sudz;

/**
 * Строка шага 5 {@code cipuCn_AgNotLoad}: договор из Tbl (исполнитель+№) без данного агента в БД.
 *
 * @param cnKey ключ договора
 * @param cnSKey существующая сторона type=1 или {@code null}
 * @param cnName нормализованный № договора
 * @param agentNum БУиРГ агента из Excel
 * @param agentName имя агента из Excel
 * @param orgIdKey {@code org_id} type=1 агента (может быть null)
 */
public record SudzPmtUplAgNotLoad(
        int cnKey,
        Integer cnSKey,
        String cnName,
        Integer agentNum,
        String agentName,
        Integer orgIdKey
) {
}
