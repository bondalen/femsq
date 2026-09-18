package com.femsq.database.model.sudz;

/**
 * Строка шага 3 {@code cipuCn_CtptCnNotLoad}: пара БУиРГ+№ из Tbl без исполнителя в БД.
 * {@code countCn} — сколько раз этот № уже есть в {@code ags.cn}/{@code cnNum} (VBA SqlCipuCn_CtptCnNot);
 * INSERT только при {@code countCn == 0} и валидном {@code orgIdKey}.
 *
 * @param buirg код БУиРГ ({@code ciputCntrPrtNum})
 * @param orgIdKey ключ {@code org_id} type=1 (может быть null)
 * @param name имя контрагента из Tbl
 * @param cnName нормализованный № договора ({@code NullИлиПусто} при пустом)
 * @param countCn число совпадений № в {@code ags.cnNum}
 */
public record SudzPmtUplCnNotLoad(
        Integer buirg,
        Integer orgIdKey,
        String name,
        String cnName,
        int countCn
) {
}
