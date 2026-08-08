package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * GraphQL input создания выгрузки ДЗ.
 *
 * @param name имя
 * @param uplDate дата выгрузки
 * @param statusOnDate дата состояния
 */
public record CreateSudzUplInput(
        String name,
        LocalDate uplDate,
        LocalDate statusOnDate
) {
}
