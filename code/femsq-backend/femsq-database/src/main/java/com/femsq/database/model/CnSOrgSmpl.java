package com.femsq.database.model;

import java.time.LocalDateTime;

/**
 * Организация стороны без дат {@code ags.cn_s_org_smpl}.
 *
 * @param csosKey PK
 * @param csosCnS FK → {@code cn_s.cn_s_key}
 * @param csosOrgId FK → {@code org_id.org_id_key}
 * @param orgLabel подпись (БУиРГ + имя og)
 * @param csosTimeOfEntry время ввода
 */
public record CnSOrgSmpl(
        Integer csosKey,
        int csosCnS,
        int csosOrgId,
        String orgLabel,
        LocalDateTime csosTimeOfEntry
) {
}
