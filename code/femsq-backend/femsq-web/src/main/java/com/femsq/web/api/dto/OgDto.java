package com.femsq.web.api.dto;

/**
 * DTO представление организации {@code ags_test.og} для REST и GraphQL API.
 *
 * @param ogKey                идентификатор организации
 * @param ogName               краткое наименование
 * @param ogOfficialName       официальное наименование
 * @param ogFullName           полное наименование
 * @param ogDescription        описание организации
 * @param inn                  ИНН
 * @param kpp                  КПП
 * @param ogrn                 ОГРН
 * @param okpo                 код ОКПО
 * @param oe                   код отрасли экономики
 * @param registrationTaxType  режим налогового учета
 */
public record OgDto(
        Integer ogKey,
        String ogName,
        String ogOfficialName,
        String ogFullName,
        String ogDescription,
        Double inn,
        Double kpp,
        Double ogrn,
        Double okpo,
        Integer oe,
        String registrationTaxType
) {
}
