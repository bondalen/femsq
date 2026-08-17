package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * {@code cn_s_org}.
 */
public record CnSOrgDto(
        Integer cnSOrgKey,
        Integer csoCnSOrgSmpl,
        LocalDate dateBeg,
        LocalDate dateEnd,
        String csoAsbuId,
        LocalDate csoCnDate,
        String csoTimeOfEntry
) {
}
