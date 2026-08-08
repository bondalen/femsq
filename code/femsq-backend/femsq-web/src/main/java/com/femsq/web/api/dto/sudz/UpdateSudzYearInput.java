package com.femsq.web.api.dto.sudz;

/**
 * GraphQL input обновления год-варианта СУДЗ ({@code yr_Progress} не меняется).
 *
 * @param yrKey ключ года
 * @param variant описание
 * @param baseUplKey базовая выгрузка
 * @param yKey ключ {@code ags.yyyy}
 * @param cmmGrKey группа комментариев (nullable)
 */
public record UpdateSudzYearInput(
        int yrKey,
        String variant,
        int baseUplKey,
        int yKey,
        Integer cmmGrKey
) {
}
