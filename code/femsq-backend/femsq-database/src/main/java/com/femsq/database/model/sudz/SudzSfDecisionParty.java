package com.femsq.database.model.sudz;

/**
 * Сторона договора кандидата СФ ({@code cn_s} → {@code org_id} type=1).
 *
 * @param csosKey ключ {@code cn_s_org_smpl}
 * @param cnSType 1=агент, 2=исполнитель
 * @param buirg БУиРГ
 * @param name имя {@code og.ogNm}
 * @param hitExcel совпал с БУиРГ Excel-кандидата
 */
public record SudzSfDecisionParty(
        int csosKey,
        int cnSType,
        Integer buirg,
        String name,
        boolean hitExcel
) {
}
