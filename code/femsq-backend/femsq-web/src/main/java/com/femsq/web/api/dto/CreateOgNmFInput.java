package com.femsq.web.api.dto;

import java.time.LocalDate;

/**
 * Создание варианта имени.
 *
 * @param onfOg ogKey
 * @param onfName организация
 * @param onfNameExt филиал
 * @param onfStart начало
 * @param onfEnd конец
 */
public record CreateOgNmFInput(
        int onfOg,
        String onfName,
        String onfNameExt,
        LocalDate onfStart,
        LocalDate onfEnd
) {
}
