package com.femsq.database.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Организация стороны с датами {@code ags.cn_s_org}.
 *
 * @param cnSOrgKey PK
 * @param csoCnSOrgSmpl FK → {@code cn_s_org_smpl.csosKey}
 * @param dateBeg начало
 * @param dateEnd конец
 * @param csoAsbuId ID в АСБУ
 * @param csoCnDate дата для орг. (критична для СУДЗ)
 * @param csoTimeOfEntry время ввода
 */
public record CnSOrg(
        Integer cnSOrgKey,
        int csoCnSOrgSmpl,
        LocalDate dateBeg,
        LocalDate dateEnd,
        String csoAsbuId,
        LocalDate csoCnDate,
        LocalDateTime csoTimeOfEntry
) {
}
