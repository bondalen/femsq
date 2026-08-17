package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Строка шага {@code CnExistCtptNotLoad}: номер договора уже в БД, но нет пары
 * «номер + дата + исполнитель (БУиРГ)» ({@code ciduCnExistCtptNot}).
 *
 * @param buirg код БУиРГ ({@code cidutCntrPrtNum})
 * @param name имя контрагента
 * @param itn ИНН из свода
 * @param cnName нормализованный номер ({@code cidutCnNameNull})
 * @param cnDate дата после Nz→1900-01-01 ({@code cidutCnDateNull})
 * @param cnCount сколько {@code ags.cn} с этим номером ({@code HAVING Count &gt; 0})
 */
public record SudzDbtUplCnExistCtptNotLoad(
        Integer buirg,
        String name,
        String itn,
        String cnName,
        LocalDate cnDate,
        int cnCount
) {
}
