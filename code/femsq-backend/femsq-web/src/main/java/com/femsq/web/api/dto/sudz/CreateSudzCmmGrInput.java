package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * GraphQL input создания группы комментариев.
 *
 * @param name имя группы
 * @param date дата группы
 */
public record CreateSudzCmmGrInput(String name, LocalDate date) {
}
