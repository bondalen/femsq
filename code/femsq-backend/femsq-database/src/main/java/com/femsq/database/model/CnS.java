package com.femsq.database.model;

/**
 * Сторона договора {@code ags.cn_s}.
 *
 * @param cnSKey PK
 * @param cnKey FK → {@code cn.cn_key}
 * @param cnSType FK → {@code cn_s_type.cn_s_t_key} (1=заказчик, 2=исполнитель)
 * @param cnSTypeName подпись роли
 */
public record CnS(
        Integer cnSKey,
        int cnKey,
        int cnSType,
        String cnSTypeName
) {
}
