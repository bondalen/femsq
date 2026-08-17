package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Строка шага {@code CnNotLoad}: договор из свода без пары в БД
 * (номер + дата + исполнитель / отсутствие номера в {@code ags.cnNum}).
 *
 * @param buirg код БУиРГ ({@code cidutCntrPrtNum})
 * @param orgIdKey ключ {@code org_id} type=1
 * @param name имя контрагента ({@code ogNm} / свод)
 * @param itn ИНН из свода
 * @param cnName нормализованный номер договора ({@code cidutCnNameNull})
 * @param cnDate дата договора после Nz→1900-01-01 ({@code cidutCnDateNull})
 * @param cnCount всегда 0 в отборе Access ({@code HAVING Count=0})
 * @param countCnName сколько раз этот номер среди «новых»
 */
public record SudzDbtUplCnNotLoad(
        Integer buirg,
        Integer orgIdKey,
        String name,
        String itn,
        String cnName,
        LocalDate cnDate,
        int cnCount,
        int countCnName
) {
}
