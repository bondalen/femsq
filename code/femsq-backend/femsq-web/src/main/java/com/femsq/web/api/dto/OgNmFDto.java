package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * DTO {@code ags.ogNmF}.
 *
 * @param onfKey PK
 * @param onfOg FK og
 * @param onfName организация
 * @param onfNameExt филиал
 * @param onfStart начало
 * @param onfEnd конец
 */
public record OgNmFDto(
        Integer onfKey,
        int onfOg,
        String onfName,
        String onfNameExt,
        LocalDate onfStart,
        LocalDate onfEnd
) {
}
