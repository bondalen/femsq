package com.femsq.database.model.sudz;

/**
 * Организация из Excel-буфера, не найденная по коду БУиРГ ({@code org_id_type=1}).
 * {@code ogNm} заполнен, если тот же ИНН уже есть ({@code org_id_type=2}).
 *
 * @param buirg код БУиРГ ({@code cidutCntrPrtNum})
 * @param name наименование из свода
 * @param itn ИНН из свода
 * @param existingOgNm имя организации в {@code ags.og}, если ИНН совпал; иначе null
 */
public record SudzDbtUplOrgNotInBuirg(
        Integer buirg,
        String name,
        String itn,
        String existingOgNm
) {
}
