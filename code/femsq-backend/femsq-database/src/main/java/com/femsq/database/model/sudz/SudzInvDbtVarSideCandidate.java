package com.femsq.database.model.sudz;

import java.time.LocalDate;

/**
 * Кандидат стороны исполнителя ({@code cn_key} + {@code cn_s_org}) для create var.
 *
 * @param cnKey договор
 * @param cnSOrgKey {@code ags.cn_s_org.cn_s_org_key}
 * @param csoCnDate дата стороны (null → sentinel в ExistList)
 */
public record SudzInvDbtVarSideCandidate(
        int cnKey,
        int cnSOrgKey,
        LocalDate csoCnDate
) {
}
