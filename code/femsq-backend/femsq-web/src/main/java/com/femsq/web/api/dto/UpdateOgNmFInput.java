package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Обновление варианта имени.
 *
 * @param onfKey PK
 * @param onfOg ogKey
 * @param onfName организация
 * @param onfNameExt филиал
 * @param onfStart начало
 * @param onfEnd конец
 */
public record UpdateOgNmFInput(
        int onfKey,
        int onfOg,
        String onfName,
        String onfNameExt,
        LocalDate onfStart,
        LocalDate onfEnd
) {
}
