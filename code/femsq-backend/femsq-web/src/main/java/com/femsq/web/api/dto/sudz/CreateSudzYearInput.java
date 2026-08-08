package com.femsq.web.api.dto.sudz;

import java.time.LocalDate;

/**
 * GraphQL input создания год-варианта СУДЗ.
 *
 * @param variant описание варианта
 * @param yKey ключ {@code ags.yyyy}
 * @param cmmGrKey группа комментариев (nullable)
 * @param baseUplKey существующая базовая выгрузка (взаимоисключающе с newUpl*)
 * @param newUplName имя новой выгрузки
 * @param newUplDate дата новой выгрузки
 * @param newUplStatusOnDate дата состояния новой выгрузки
 */
public record CreateSudzYearInput(
        String variant,
        int yKey,
        Integer cmmGrKey,
        Integer baseUplKey,
        String newUplName,
        LocalDate newUplDate,
        LocalDate newUplStatusOnDate
) {
}
