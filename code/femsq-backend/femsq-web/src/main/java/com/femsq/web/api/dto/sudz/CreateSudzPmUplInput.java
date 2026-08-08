package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * GraphQL input создания выгрузки платежей.
 *
 * @param name имя
 * @param date дата
 */
public record CreateSudzPmUplInput(
        String name,
        LocalDate date
) {
}
